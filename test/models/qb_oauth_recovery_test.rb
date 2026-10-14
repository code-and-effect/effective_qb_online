require 'test_helper'

class QbOauthRecoveryTest < ActiveSupport::TestCase
  setup do
    @realm = Effective::QbRealm.first!
    @realm.update!(reconnection_required_at: nil, reconnection_reason: nil)
    @api = EffectiveQbOnline.api(realm: @realm)
  end

  test 'accounting service initialization does not mutate another OAuth client' do
    controller_client = EffectiveQbOnline.oauth2_client
    assert_equal 'appcenter.intuit.com', controller_client.connection.url_prefix.host
    @api.with_service('CompanyInfo') { |_service| }
    assert_equal 'appcenter.intuit.com', controller_client.connection.url_prefix.host
    refute_same controller_client, EffectiveQbOnline.oauth2_client
  end

  test 'revoke uses the official absolute endpoint with Basic auth and a JSON body' do
    client = EffectiveQbOnline.oauth2_client
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post('https://developer.api.intuit.com/v2/oauth2/tokens/revoke') do |environment|
        expected_auth = 'Basic ' + Base64.strict_encode64("#{client.id}:#{client.secret}")
        assert_equal expected_auth, environment.request_headers['Authorization']
        assert_equal 'application/json', environment.request_headers['Content-Type']
        assert_equal({ 'token' => @realm.refresh_token }, JSON.parse(environment.body))
        assert_nil environment.url.query
        [200, {}, '']
      end
    end
    client.connection = Faraday.new { |connection| connection.adapter :test, stubs }
    stub(EffectiveQbOnline, :oauth2_client, client) { assert EffectiveQbOnline.revoke_token!(@realm) }
    stubs.verify_stubbed_calls
  end

  test 'terminal refresh failure records reconnect state and sends only one notice' do
    error = oauth_error(400, 'invalid_grant', 'x_error_reason' => 'user_not_in_realm')
    notices = []
    stub(OAuth2::AccessToken, :new, failing_token(error)) do
      stub(EffectiveQbOnline, :send_email, ->(*args) { notices << args }) do
        assert_raises(EffectiveQbOnline::ReconnectionRequired) { authenticate { raise oauth_error(401, 'unauthorized') } }
        assert_raises(EffectiveQbOnline::ReconnectionRequired) { authenticate { flunk 'provider must not be called' } }
      end
    end
    assert @realm.reload.reconnection_required?
    assert_equal 'user_not_in_realm', @realm.reconnection_reason
    assert_equal 1, notices.length
    assert_equal :reconnection_required, notices.first.first
    assert_equal 'account', @realm.deposit_to_account_id
  end

  test 'provider failures and invalid client errors do not require reconnection' do
    [oauth_error(503, 'temporarily_unavailable'), oauth_error(401, 'invalid_client'), Faraday::TimeoutError.new('timeout')].each do |error|
      stub(OAuth2::AccessToken, :new, failing_token(error)) do
        raised = assert_raises(error.class) { authenticate { raise oauth_error(401, 'unauthorized') } }
        assert_same error, raised
      end
      refute @realm.reload.reconnection_required?
    end
  end

  test 'non authentication OAuth errors are not refreshed' do
    token = failing_token(RuntimeError.new('must not refresh'))
    stub(OAuth2::AccessToken, :new, token) do
      error = oauth_error(429, 'rate_limited')
      assert_same error, assert_raises(OAuth2::Error) { authenticate { raise error } }
    end
    refute @realm.reload.reconnection_required?
  end

  test 'successful refresh saves rotated tokens and provider refresh lifetime' do
    client = EffectiveQbOnline.oauth2_client
    refreshed = OAuth2::AccessToken.new(client, 'new-access', refresh_token: 'new-refresh', expires_in: 3600, 'x_refresh_token_expires_in' => 7200)
    token = failing_token(nil, refreshed: refreshed)
    calls = 0
    stub(OAuth2::AccessToken, :new, ->(*args, **options) { calls += 1; calls == 1 ? token : refreshed }) do
      attempts = 0
      assert_equal 'new-access', authenticate { |access| attempts += 1; raise oauth_error(401, 'unauthorized') if attempts == 1; access.token }
    end
    assert_equal 'new-refresh', @realm.reload.refresh_token
    assert_equal 'new-access', @realm.access_token
    assert_in_delta 7200, @realm.refresh_token_expires_at - Time.current, 5
  end

  test 'a concurrent token rotation is reused without refreshing stale credentials' do
    initial_token = OAuth2::AccessToken.new(EffectiveQbOnline.oauth2_client, @realm.access_token, refresh_token: @realm.refresh_token)
    initial_token.define_singleton_method(:refresh!) { raise 'stale token must not refresh' }
    new_token = OAuth2::AccessToken.new(EffectiveQbOnline.oauth2_client, 'other-access', refresh_token: 'other-refresh')
    calls = 0
    stub(OAuth2::AccessToken, :new, ->(*args, **options) { calls += 1; calls == 1 ? initial_token : new_token }) do
      attempts = 0
      result = authenticate do |access|
        attempts += 1
        if attempts == 1
          Effective::QbRealm.find(@realm.id).update!(access_token: 'other-access', refresh_token: 'other-refresh')
          raise oauth_error(401, 'unauthorized')
        end
        access.token
      end
      assert_equal 'other-access', result
    end
    refute @realm.reload.reconnection_required?
  end

  test 'paused sync keeps the receipt errored without a remote call or repeated email' do
    @realm.update!(reconnection_required_at: Time.current, reconnection_reason: 'user_not_in_realm')
    order = Effective::Order.new(status: 'purchased', purchased_at: Time.current, billing_name: 'Test Customer', total: 12000, tax_rate: 0)
    order.save!(validate: false)
    item = order.order_items.build(name: 'Test Fee', price: 12000, quantity: 1, tax_exempt: true)
    item.save!(validate: false)
    receipt = Effective::QbReceipt.create_from_order!(order)
    stub(EffectiveQbOnline, :send_email, ->(*) { flunk 'must not repeat notice for blocked receipts' }) do
      refute receipt.sync!
    end
    assert_equal 'errored', receipt.reload.status
    assert_nil receipt.sales_receipt_id
    assert_includes receipt.result, 'Retry this receipt manually'
  end

  test 'reconnection notice renders manual recovery instructions' do
    message = Effective::QbOnlineMailer.reconnection_required(@realm).message
    assert_includes message.body.to_s, 'retry them manually'
    assert_includes message.body.to_s, '/admin/quickbooks'
    assert_equal 'Have a great day!', Nokogiri::HTML.fragment(message.body.to_s).css('p').last.text
  end

  test 'revoke preserves connection settings on provider rejection or timeout' do
    [OAuth2::Error.new('error' => 'invalid_grant'), Faraday::TimeoutError.new('timeout')].each do |error|
      controller = controller_for
      stub(EffectiveQbOnline, :revoke_token!, ->(*) { raise error }) { controller.revoke }
      assert Effective::QbRealm.exists?(@realm.id)
      assert_equal '/admin/quickbooks', controller.instance_variable_get(:@test_redirect)
      assert controller.flash[:danger].present?
    end
  end

  test 'successful revoke deletes the realm and missing realm redirects safely' do
    controller = controller_for
    stub(EffectiveQbOnline, :revoke_token!, true) { controller.revoke }
    refute Effective::QbRealm.exists?(@realm.id)
    controller.revoke
    assert_equal '/admin/quickbooks', controller.instance_variable_get(:@test_redirect)
    assert_equal 'Already disconnected from QuickBooks Online', controller.flash[:success]
  end

  test 'authorization stores a state and rejects callbacks with a mismatched state' do
    controller = controller_for
    controller.authorize
    state = controller.session[:qb_oauth_state]
    assert state.present?
    assert_includes controller.instance_variable_get(:@test_redirect), "state=#{state}"
    controller.params = ActionController::Parameters.new(code: 'code', realmId: @realm.realm_id, state: 'wrong')
    stub(EffectiveQbOnline, :oauth2_client, -> { flunk 'must not exchange invalid state' }) { controller.callback }
    assert_nil controller.session[:qb_oauth_state]
    assert controller.flash[:danger].present?
  end

  test 'reconnection clears the paused state and preserves account settings without syncing receipts' do
    @realm.update!(reconnection_required_at: Time.current, reconnection_reason: 'invalid_grant')
    controller = controller_for
    controller.session[:qb_oauth_state] = 'correct-state'
    controller.params = ActionController::Parameters.new(code: 'code', realmId: @realm.realm_id, state: 'correct-state')
    token = OAuth2::AccessToken.new(EffectiveQbOnline.oauth2_client, 'reconnected-access', refresh_token: 'reconnected-refresh', expires_in: 3600, 'x_refresh_token_expires_in' => 7200)
    client = EffectiveQbOnline.oauth2_client
    stub(client.auth_code, :get_token, token) do
      stub(EffectiveQbOnline, :oauth2_client, client) do
        stub(EffectiveQbOnline, :sync_order!, ->(*) { flunk 'reconnection must not retry receipts' }) { controller.callback }
      end
    end
    refute @realm.reload.reconnection_required?
    assert_nil @realm.reconnection_reason
    assert_equal 'account', @realm.deposit_to_account_id
    assert_equal 'reconnected-refresh', @realm.refresh_token
    assert_in_delta 7200, @realm.refresh_token_expires_at - Time.current, 5
  end

  test 'reconnecting a different company is rejected before exchanging the code' do
    @realm.update!(reconnection_required_at: Time.current, reconnection_reason: 'invalid_grant')
    controller = controller_for
    controller.session[:qb_oauth_state] = 'correct-state'
    controller.params = ActionController::Parameters.new(code: 'code', realmId: 'wrong-company', state: 'correct-state')
    stub(EffectiveQbOnline, :oauth2_client, -> { flunk 'must not exchange for another company' }) { controller.callback }
    assert_equal 'realm', @realm.reload.realm_id
    assert @realm.reconnection_required?
    assert_equal 'account', @realm.deposit_to_account_id
    assert_includes controller.flash[:danger], 'existing QuickBooks company'
  end

  test 'callback provider errors preserve existing credentials and allow another authorization attempt' do
    @realm.update!(reconnection_required_at: Time.current, reconnection_reason: 'invalid_grant')
    original_token = @realm.refresh_token
    controller = controller_for
    controller.session[:qb_oauth_state] = 'correct-state'
    controller.params = ActionController::Parameters.new(code: 'code', realmId: @realm.realm_id, state: 'correct-state')
    client = EffectiveQbOnline.oauth2_client
    stub(client.auth_code, :get_token, ->(*) { raise Faraday::TimeoutError, 'timeout' }) do
      stub(EffectiveQbOnline, :oauth2_client, client) { controller.callback }
    end
    assert_equal original_token, @realm.reload.refresh_token
    assert @realm.reconnection_required?
    assert controller.flash[:danger].present?
    assert_nil controller.session[:qb_oauth_state]
  end

  test 'an existing API instance uses credentials from a later successful reconnection' do
    assert_equal @realm.access_token, authenticate(&:token)
    @realm.update!(access_token: 'reconnected-access', refresh_token: 'reconnected-refresh')
    assert_equal 'reconnected-access', authenticate(&:token)
  end

  test 'revoking an old grant preserves a concurrent reconnection' do
    controller = controller_for
    stub(EffectiveQbOnline, :revoke_token!, ->(realm) { Effective::QbRealm.find(realm.id).update!(access_token: 'new-access', refresh_token: 'new-refresh'); true }) do
      controller.revoke
    end
    assert_equal 'new-refresh', @realm.reload.refresh_token
    assert_includes controller.flash[:danger], 'newer connection has been preserved'
  end

  test 'the first failing admin page displays reconnect instructions immediately' do
    error = oauth_error(400, 'invalid_grant', 'x_error_reason' => 'user_not_in_realm')
    stub(@api, :company_info, -> { @api.send(:with_authenticated_request) { raise oauth_error(401, 'unauthorized') } }) do
      stub(OAuth2::AccessToken, :new, failing_token(error)) do
        stub(EffectiveQbOnline, :send_email, true) do
          stub(EffectiveQbOnline, :api, @api) do
            html = render_admin_page
            assert_includes html, 'Reconnect QuickBooks'
            refute_includes html, 'Show Company Settings'
          end
        end
      end
    end
  end

  test 'a concurrent disconnect while revoking returns an already disconnected response' do
    controller = controller_for
    stub(EffectiveQbOnline, :revoke_token!, ->(realm) { Effective::QbRealm.find(realm.id).destroy!; true }) { controller.revoke }
    assert_equal 'Already disconnected from QuickBooks Online', controller.flash[:success]
    assert_equal '/admin/quickbooks', controller.instance_variable_get(:@test_redirect)
  end

  test 'a concurrent disconnect during callback does not resurrect the old settings' do
    controller = controller_for
    controller.session[:qb_oauth_state] = 'correct-state'
    controller.params = ActionController::Parameters.new(code: 'code', realmId: @realm.realm_id, state: 'correct-state')
    token = OAuth2::AccessToken.new(EffectiveQbOnline.oauth2_client, 'new-access', refresh_token: 'new-refresh', expires_in: 3600)
    client = EffectiveQbOnline.oauth2_client
    stub(client.auth_code, :get_token, ->(*) { @realm.destroy!; token }) do
      stub(EffectiveQbOnline, :oauth2_client, client) { controller.callback }
    end
    refute Effective::QbRealm.exists?(@realm.id)
    assert controller.flash[:danger].present?
  end

  test 'a notification enqueue failure leaves the connection paused and is reported once' do
    delivery = Object.new
    delivery.define_singleton_method(:deliver_later) { raise Faraday::TimeoutError, 'enqueue failed' }
    mailer = Object.new
    mailer.define_singleton_method(:reconnection_required) { |_realm| delivery }
    reports = []
    stub(EffectiveQbOnline, :mailer_class, mailer) do
      stub(EffectiveQbOnline, :deliver_method, :deliver_later) do
        stub(Rails.env, :production?, true) do
          stub(EffectiveResources, :send_error, ->(error, **) { reports << error }) do
            assert @realm.require_reconnection!(reason: 'invalid_grant', refresh_token: @realm.refresh_token)
            refute @realm.require_reconnection!(reason: 'invalid_grant', refresh_token: @realm.refresh_token)
          end
        end
      end
    end
    assert @realm.reload.reconnection_required?
    assert_equal 1, reports.length
  end

  test 'reconnection between refresh failure and state recording continues with the new grant' do
    error = oauth_error(400, 'invalid_grant')
    old_token = failing_token(error)
    new_token = OAuth2::AccessToken.new(EffectiveQbOnline.oauth2_client, 'reconnected-access', refresh_token: 'reconnected-refresh')
    require_reconnection = @realm.method(:require_reconnection!)
    record_failure = ->(**options) do
      Effective::QbRealm.find(@realm.id).update!(access_token: 'reconnected-access', refresh_token: 'reconnected-refresh')
      require_reconnection.call(**options)
    end
    calls = 0
    stub(@realm, :require_reconnection!, record_failure) do
      stub(OAuth2::AccessToken, :new, ->(*, **) { calls += 1; calls == 1 ? old_token : new_token }) do
        stub(EffectiveQbOnline, :send_email, ->(*) { flunk 'the new grant must not be marked invalid' }) do
          result = authenticate do |token|
            raise oauth_error(401, 'unauthorized') if token.token == old_token.token
            token.token
          end
          assert_equal 'reconnected-access', result
        end
      end
    end
    refute @realm.reload.reconnection_required?
  end

  private

  # Minitest 6 extracts its mocking helpers into a separate gem. Keep these
  # offline tests independent of additional development dependencies.
  def stub(object, name, value)
    original = object.method(name)
    object.define_singleton_method(name) do |*args, **options, &block|
      value.respond_to?(:call) ? value.call(*args, **options, &block) : value
    end
    yield
  ensure
    object.define_singleton_method(name, original)
  end

  def render_admin_page
    controller = Admin::QbOnlineController.new
    controller.set_request!(ActionDispatch::TestRequest.create)
    view = controller.view_context
    # Receipt datatable state needs browser cookies; it is outside this view unit's scope.
    view.define_singleton_method(:render_datatable) { |_datatable| '<table>Receipts</table>'.html_safe }
    view.render(template: 'admin/qb_online/index')
  end

  def controller_for
    controller = Effective::QbOauthController.new
    session = {}
    flash = {}
    controller.define_singleton_method(:session) { session }
    controller.define_singleton_method(:flash) { flash }
    controller.define_singleton_method(:effective_qb_online) { EffectiveQbOnline::Engine.routes.url_helpers }
    controller.define_singleton_method(:redirect_uri) { 'https://example.com/quickbooks/oauth/callback' }
    controller.define_singleton_method(:redirect_to) { |url, **| @test_redirect = url }
    controller
  end

  def authenticate(&block)
    @api.send(:with_authenticated_request, &block)
  end

  def oauth_error(status, code, details = {})
    response = Faraday::Response.new(status: status, response_headers: { 'Content-Type' => 'application/json' }, body: { error: code }.merge(details).to_json)
    OAuth2::Error.new(OAuth2::Response.new(response))
  end

  def failing_token(error, refreshed: nil)
    token = OAuth2::AccessToken.new(EffectiveQbOnline.oauth2_client, @realm.access_token, refresh_token: @realm.refresh_token)
    token.define_singleton_method(:refresh!) { raise error if error; refreshed }
    token
  end
end
