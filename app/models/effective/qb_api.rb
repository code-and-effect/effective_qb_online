# The Quickbooks namespace comes from quickbooks-ruby gem
# https://github.com/ruckus/quickbooks-ruby

module Effective
  class QbApi
    attr_accessor :realm

    def initialize(realm:)
      raise('expected an Effective::QbRealm') unless realm.kind_of?(Effective::QbRealm)
      @realm = realm
    end

    # Singular
    def company_info
      with_authenticated_request do |access_token|
        service = Quickbooks::Service::CompanyInfo.new(company_id: realm.company_id, access_token: access_token)
        service.fetch_by_id(realm.company_id)
      end
    end

    def customers
      with_authenticated_request do |access_token|
        service = Quickbooks::Service::Customer.new(company_id: realm.company_id, access_token: access_token)
        service.query()
      end
    end

    def customers_count
      with_authenticated_request do |access_token|
        service = Quickbooks::Service::Customer.new(company_id: realm.company_id, access_token: access_token)
        service.query('SELECT COUNT(*) FROM Customer').total_count
      end
    end

    def invoices
      with_authenticated_request do |access_token|
        service = Quickbooks::Service::Invoice.new(company_id: realm.company_id, access_token: access_token)
        service.query()
      end
    end

    def invoices_count
      with_authenticated_request do |access_token|
        service = Quickbooks::Service::Invoice.new(company_id: realm.company_id, access_token: access_token)
        service.query('SELECT COUNT(*) FROM Invoice').total_count
      end
    end

    def find_item(id: nil, name: nil)
      raise('expected either an id or name') unless id.present? || name.present?

      with_authenticated_request do |access_token|
        service = Quickbooks::Service::Item.new(company_id: realm.company_id, access_token: access_token)

        return service.find_by(:id, id) if id.present?
        return service.find_by(:name, name) if name.present?
      end
    end

    def create_sales_receipt(sales_receipt:)
      with_authenticated_request do |access_token|
        service = Quickbooks::Service::SalesReceipt.new(company_id: realm.company_id, access_token: access_token)
        service.create(sales_receipt)
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
        puts "Quickbooks OAuth Error: #{e.message}"

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
