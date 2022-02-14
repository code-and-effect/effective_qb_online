# The Quickbooks namespace comes from quickbooks-ruby gem
# https://github.com/ruckus/quickbooks-ruby

module Effective
  class QbApi
    attr_accessor :realm

    def initialize(realm:)
      raise('expected an Effective::QbRealm') unless realm.kind_of?(Effective::QbRealm)
      @realm = realm
    end

    def customers
      with_authenticated_request do |access_token|
        service = Quickbooks::Service::Customer.new(company_id: realm.company_id, access_token: access_token)
        service.query()
      end
    end

    def invoices
      with_authenticated_request do |access_token|
        service = Quickbooks::Service::Invoice.new(company_id: realm.company_id, access_token: access_token)
        service.query()
      end
    end

    private

    def with_authenticated_request(max_attempts: 3, &block)
      raise('expected a block') unless block_given?

      attempts = 0

      begin
        token = OAuth2::AccessToken.new(EffectiveQbOnline.oauth2_client, realm.access_token, refresh_token: realm.refresh_token)
        yield(token)
      rescue OAuth2::Error, Quickbooks::AuthorizationFailure => e
        attempts += 1
        raise "unable to refresh Quickbooks OAuth2 token" if attempts >= max_attempts

        # Refresh
        refreshed = token.refresh!

        realm.update!(
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
