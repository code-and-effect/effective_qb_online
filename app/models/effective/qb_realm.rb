# One Quickbooks Realm / Company

module Effective
  class QbRealm < ActiveRecord::Base

    effective_resource do
      realm_id                    :string

      access_token                :text
      access_token_expires_at     :datetime

      refresh_token               :text
      refresh_token_expires_at    :datetime

      timestamps
    end

    validates :realm_id, presence: true
    validates :realm_id, uniqueness: true, if: -> { new_record? }

    validates :access_token, presence: true
    validates :access_token_expires_at, presence: true

    validates :refresh_token, presence: true
    validates :refresh_token_expires_at, presence: true

    def to_s
      realm_id.presence || 'New Quickbooks Realm'
    end

    def company_id
      realm_id
    end

    def with_authenticated_request(max_attempts: 3, &block)
      raise('expected a block') unless block_given?

      attempts = 0

      begin
        token = OAuth2::AccessToken.new(EffectiveQbOnline.oauth2_client, access_token, refresh_token: refresh_token)
        yield(token)
      rescue OAuth2::Error, Quickbooks::AuthorizationFailure => e
        attempts += 1
        raise "unable to refresh Quickbooks OAuth2 token" if attempts >= max_attempts

        # Refresh
        refreshed = token.refresh!

        update!(
          access_token: refreshed.token,
          refresh_token: refreshed.refresh_token,
          access_token_expires_at: Time.at(refreshed.expires_at),
          refresh_token_expires_at: (Time.at(refreshed.expires_at) + 100.days)
        )

        retry
      end
    end

  end
end
