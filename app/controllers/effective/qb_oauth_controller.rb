# http://caaa.test:3000/quickbooks/oauth/authorize

module Effective
  class QbOauthController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    # Any user that has priviledges with the QuickBooks Online company could authenticate
    # But we assume this user also has admin priviledges on our site
    # This should only be done once anyway
    before_action { EffectiveResources.authorize!(self, :admin, :effective_qb_online) }

    def authorize
      grant_url = client.auth_code.authorize_url(
        redirect_uri: redirect_uri,
        response_type: 'code',
        state: SecureRandom.hex(12),
        scope: 'com.intuit.quickbooks.accounting'
      )

      redirect_to(grant_url, allow_other_host: true)
    end

    # This matches the QuickBooks Redirect URI and we have to set it up ahead of time.
    def callback
      return unless params[:code].present? && params[:realmId].present? && params[:state].present?

      token = client.auth_code.get_token(params[:code], redirect_uri: redirect_uri)
      return unless token

      realm = Effective::QbRealm.all.first_or_initialize

      realm.update!(
        realm_id: params[:realmId],
        access_token: token.token,
        refresh_token: token.refresh_token,
        access_token_expires_at: Time.at(token.expires_at),
        refresh_token_expires_at: (Time.at(token.expires_at) + 100.days)
      )

      flash[:success] = 'Successfully connected with QuickBooks Online'

      redirect_to(effective_qb_online.admin_quickbooks_path, allow_other_host: true)
    end

    def revoke
      realm = EffectiveQbOnline.api.realm
      return unless realm

      # Instantiate the token
      token = OAuth2::AccessToken.new(client, realm.access_token, refresh_token: realm.refresh_token)

      # Revoke
      response = token.post('/o/oauth2/revoke', params: { token: realm.refresh_token })

      if response.status == 200
        flash[:success] = 'Successfully revoked from QuickBooks Online'
        realm.destroy!
      else
        flash[:danger] = 'Unable to revoke'
      end

      redirect_to(effective_qb_online.admin_quickbooks_path, allow_other_host: true)
    end

    private

    def client
      EffectiveQbOnline.oauth2_client
    end

    def redirect_uri
      effective_qb_online.quickbooks_oauth_callback_url
    end

  end
end
