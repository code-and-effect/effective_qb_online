# http://caaa.test:3000/quickbooks/oauth/authorize

module Effective
  class QbOauthController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    # Any user that has priviledges with the QuickBooks Online company could authenticate
    # But we assume this user also has admin priviledges on our site
    # This should only be done once anyway
    before_action { EffectiveResources.authorize!(self, :admin, :effective_qb_online) }

    def authorize
      session[:qb_oauth_state] = SecureRandom.hex(24)
      grant_url = client.auth_code.authorize_url(
        redirect_uri: redirect_uri,
        response_type: 'code',
        state: session[:qb_oauth_state],
        scope: 'com.intuit.quickbooks.accounting'
      )

      redirect_to(grant_url, allow_other_host: true)
    end

    # This matches the QuickBooks Redirect URI and we have to set it up ahead of time.
    def callback
      expected_state = session.delete(:qb_oauth_state)
      unless expected_state.present? && params[:state].present? && ActiveSupport::SecurityUtils.secure_compare(expected_state, params[:state].to_s)
        flash[:danger] = 'Invalid QuickBooks authorization response. Please start the connection again.'
        return redirect_to(effective_qb_online.admin_quickbooks_path)
      end

      unless params[:code].present? && params[:realmId].present?
        flash[:danger] = 'QuickBooks authorization was not completed. Please try again.'
        return redirect_to(effective_qb_online.admin_quickbooks_path)
      end

      realm = Effective::QbRealm.all.first_or_initialize
      if realm.persisted? && realm.realm_id != params[:realmId].to_s
        flash[:danger] = 'Please reconnect the existing QuickBooks company. Selecting another company would invalidate your account settings and receipt history.'
        return redirect_to(effective_qb_online.admin_quickbooks_path)
      end

      token = client.auth_code.get_token(params[:code], redirect_uri: redirect_uri)

      realm.with_lock do
        realm.update!(
          realm_id: params[:realmId],
          access_token: token.token,
          refresh_token: token.refresh_token,
          access_token_expires_at: Time.at(token.expires_at),
          refresh_token_expires_at: Time.current + token.params.fetch('x_refresh_token_expires_in', 100.days).to_i.seconds,
          reconnection_required_at: nil,
          reconnection_reason: nil
        )
      end

      flash[:success] = 'Successfully connected with QuickBooks Online'

      redirect_to(effective_qb_online.admin_quickbooks_path, allow_other_host: true)
    rescue OAuth2::Error, Faraday::Error, ActiveRecord::RecordNotFound
      flash[:danger] = 'QuickBooks authorization could not be completed. Please start the connection again.'
      redirect_to(effective_qb_online.admin_quickbooks_path)
    end

    def revoke
      realm = Effective::QbRealm.first

      if realm.blank?
        flash[:success] = 'Already disconnected from QuickBooks Online'
      else
        revoked_refresh_token = realm.refresh_token
        unless EffectiveQbOnline.revoke_token!(realm)
          flash[:danger] = 'Unable to revoke QuickBooks access. Please try again or reconnect using a current company administrator.'
          return redirect_to(effective_qb_online.admin_quickbooks_path)
        end

        realm.with_lock do
          if realm.refresh_token == revoked_refresh_token
            realm.destroy!
            flash[:success] = 'Successfully revoked from QuickBooks Online'
          else
            flash[:danger] = 'The QuickBooks connection changed while revoking access. Your newer connection has been preserved.'
          end
        end
      end

      redirect_to(effective_qb_online.admin_quickbooks_path)
    rescue ActiveRecord::RecordNotFound
      flash[:success] = 'Already disconnected from QuickBooks Online'
      redirect_to(effective_qb_online.admin_quickbooks_path)
    rescue OAuth2::Error
      flash[:danger] = 'QuickBooks could not revoke access. Your connection settings have been preserved. Please reconnect or try again.'
      redirect_to(effective_qb_online.admin_quickbooks_path)
    rescue Faraday::Error
      flash[:danger] = 'Unable to reach QuickBooks Online. Please try again.'
      redirect_to(effective_qb_online.admin_quickbooks_path)
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
