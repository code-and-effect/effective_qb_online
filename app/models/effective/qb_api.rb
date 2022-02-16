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

    # Singular
    def company_info
      with_service('CompanyInfo') { |service| service.fetch_by_id(realm.company_id) }
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
        .group_by(&:third)
    end

    def items
      with_service('Item') { |service| service.all }
    end

    def items_collection
      items
        .sort_by { |item| [item.type, item.name] }
        .map { |item| [item.name, item.id, item.type] }
        .group_by(&:third)
    end

    def find_item(id: nil, name: nil)
      raise('expected either an id or name') unless id.present? || name.present?

      with_service('Item') do |service|
        return service.find_by(:id, id) if id.present?
        return service.find_by(:name, name) if name.present?
      end
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
        return customer if customer.present?

        # Find by given name and family name
        if user.respond_to?(:first_name) && user.respond_to?(:last_name)
          customer = service.query("SELECT * FROM Customer WHERE GivenName LIKE '#{user.first_name}' AND FamilyName LIKE '#{user.last_name}'")&.first
          return customer if customer.present?
        end

        # Find by display name
        customer = service.find_by(:display_name, user.to_s)&.first
        return customer if customer.present?
      end

      nil
    end

    def create_customer(user:)
      raise('expected a user that responds to email') unless user.respond_to?(:email)

      with_service('Customer') do |service|
        customer = Quickbooks::Model::Customer.new(
          primary_email_address: Quickbooks::Model::EmailAddress.new(user.email)
        )

        if user.respond_to?(:first_name) && user.respond_to?(:last_name)
          customer.given_name = user.first_name
          customer.family_name = user.last_name
        else
          customer.display_name = user.to_s
        end

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

    private

    def with_service(name, &block)
      klass = "Quickbooks::Service::#{name}".constantize

      with_authenticated_request do |access_token|
        service = klass.new(company_id: realm.company_id, access_token: access_token)
        yield(service)
      end
    end

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
