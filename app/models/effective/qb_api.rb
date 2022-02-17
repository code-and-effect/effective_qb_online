# The Quickbooks namespace comes from quickbooks-ruby gem
# https://github.com/ruckus/quickbooks-ruby

module Effective
  class QbApi
    attr_accessor :realm

    def initialize(realm:)
      raise('expected an Effective::QbRealm') unless realm.kind_of?(Effective::QbRealm)
      @realm = realm
    end

    def app_url
      Quickbooks.sandbox_mode ? 'https://app.sandbox.qbo.intuit.com/app' : 'https://app.qbo.intuit.com/app'
    end

    def sales_receipt_url(obj)
      "#{app_url}/salesreceipt?txnId=#{obj.try(:sales_receipt_id) || obj.try(:id) || obj}"
    end

    def customer_url(obj)
      "#{app_url}/customerdetail?nameId=#{obj.try(:customer_id) || obj.try(:id) || obj}"
    end

    def price_to_amount(price)
      raise('Expected an Integer price') unless price.kind_of?(Integer)
      (price / 100.0).round(2)
    end

    def build_address(address)
      raise('Expected a Effective::Address') unless address.kind_of?(Effective::Address)

      Quickbooks::Model::PhysicalAddress.new(
        line1: address.address1,
        line2: address.address2,
        line3: address.try(:address3),
        city: address.city,
        country: address.country,
        country_sub_division_code: address.country_code,
        postal_code: address.postal_code
      )
    end

    # Singular
    def company_info
      with_service('CompanyInfo') { |service| service.fetch_by_id(realm.realm_id) }
    end

    def accounts
      with_service('Account') { |service| service.all }
    end

    # Only accounts we can use for the Deposit to Account setting
    def accounts_collection
      accounts
        .select { |account| ['Bank', 'Other Current Asset'].include?(account.account_type) }
        .sort_by { |account| [account.account_type, account.name] }
        .map { |account| [account.name, account.id, account.account_type] }
        .group_by(&:last)
    end

    def items
      with_service('Item') { |service| service.all }
    end

    def items_collection
      items
        .reject { |item| item.type == 'Category' }
        .sort_by { |item| [item.type, item.name] }
        .map { |item| [item.name, item.id, item.type] }
        .group_by(&:last)
    end

    def payment_methods
      with_service('PaymentMethod') { |service| service.all }
    end

    def payment_methods_collection
      payment_methods.sort_by(&:name).map { |payment_method| [payment_method.name, payment_method.id] }
    end

    def find_or_create_customer(user:)
      find_customer(user: user) || create_customer(user: user)
    end

    def find_customer(user:)
      raise('expected a user that responds to email') unless user.respond_to?(:email)

      with_service('Customer') do |service|
        # Find by email
        customer = service.find_by(:PrimaryEmailAddr, user.email)&.first

        # Find by given name and family name
        customer ||= if user.respond_to?(:first_name) && user.respond_to?(:last_name)
          service.query("SELECT * FROM Customer WHERE GivenName LIKE '#{scrub(user.first_name)}' AND FamilyName LIKE '#{scrub(user.last_name)}'")&.first
        end

        # Find by display name
        customer || service.find_by(:display_name, scrub(user.to_s))&.first
      end
    end

    def create_customer(user:)
      raise('expected a user that responds to email') unless user.respond_to?(:email)

      with_service('Customer') do |service|
        customer = Quickbooks::Model::Customer.new(
          primary_email_address: Quickbooks::Model::EmailAddress.new(user.email),
          display_name: scrub(user.to_s),
          given_name: scrub(user.try(:first_name)),
          family_name: scrub(user.try(:last_name))
        )

        service.create(customer)
      end
    end

    def delete_customer(customer:)
      with_service('Customer') { |service| service.delete(customer) }
    end

    def create_sales_receipt(sales_receipt:)
      with_service('SalesReceipt') { |service| service.create(sales_receipt) }
    end

    def find_sales_receipt(id:)
      with_service('SalesReceipt') { |service| service.find_by(:id, id) }
    end

    def tax_codes
      with_service('TaxCode') { |service| service.all }
    end

    def tax_rates
      with_service('TaxRate') { |service| service.all }
    end

    # Returns a Hash of BigNumeral Tax Rate => TaxCode Object
    # { 0.0 => Quickbooks::Model::TaxCode }
    def taxes_collection
      rates = tax_rates()
      codes = tax_codes()

      # Find Exempt 0.0
      exempt = codes.find do |code|
        rate_id = code.sales_tax_rate_list.tax_rate_detail.first&.tax_rate_ref&.value
        rate = rates.find { |rate| rate.id == rate_id } if rate_id

        code.name.downcase.include?('exempt') && rate && rate.rate_value == 0.0
      end

      exempt = [[0.0, exempt]] if exempt.present?

      # Find The rest
      tax_codes = codes.map do |code|
        rate_id = code.sales_tax_rate_list.tax_rate_detail.first&.tax_rate_ref&.value
        rate = rates.find { |rate| rate.id == rate_id } if rate_id

        [rate.rate_value, code] if rate && (exempt.blank? || rate.rate_value > 0.0)
      end

      (Array(exempt) + tax_codes.compact).to_h
    end

    private

    def with_service(name, &block)
      klass = "Quickbooks::Service::#{name}".constantize

      with_authenticated_request do |access_token|
        service = klass.new(company_id: realm.realm_id, access_token: access_token)
        yield(service)
      end
    end

    def with_authenticated_request(max_attempts: 3, &block)
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

    def scrub(value)
      return nil unless value.present?
      value.gsub(':', '')
    end

  end
end
