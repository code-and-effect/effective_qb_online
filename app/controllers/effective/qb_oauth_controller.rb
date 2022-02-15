# http://caaa.test:3000/quickbooks/oauth/authorize

module Effective
  class QbOauthController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    # Any user that has priviledges with the Quickbooks Online company could authenticate
    # But we assume this user also has admin priviledges on our site
    # This should only be done once anyway
    before_action { EffectiveResources.authorize!(self, :admin, :effective_qb_online) }

    def authorize
      grant_url = EffectiveQbOnline.oauth2_client.auth_code.authorize_url(
        redirect_uri: redirect_uri,
        response_type: 'code',
        state: SecureRandom.hex(12),
        scope: 'com.intuit.quickbooks.accounting'
      )

      redirect_to(grant_url)
    end

    # This matches the Quickbooks Redirect URI and we have to set it up ahead of time.
    def callback
      return unless params[:code].present? && params[:realmId].present? && params[:state].present?

      token = EffectiveQbOnline.oauth2_client.auth_code.get_token(params[:code], redirect_uri: redirect_uri)
      return unless token

      realm = Effective::QbRealm.where(realm_id: params[:realmId]).first_or_initialize

      realm.update!(
        realm_id: params[:realmId],
        access_token: token.token,
        refresh_token: token.refresh_token,
        access_token_expires_at: Time.at(token.expires_at),
        refresh_token_expires_at: (Time.at(token.expires_at) + 100.days)
      )

      flash[:success] = 'Successfully connected with Quickbooks Online'

      redirect_to(effective_qb_online.admin_quickbooks_path)
    end

    private

    def redirect_uri
      effective_qb_online.quickbooks_oauth_callback_url
    end

  end
end
