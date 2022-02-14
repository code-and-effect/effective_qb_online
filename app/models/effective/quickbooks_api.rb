module Effective
  class QuickbooksApi
    attr_accessor :realm

    def initialize(realm:)
      raise('expected an Effective::QbRealm') unless realm.kind_of?(Effective::QbRealm)
      @realm = realm
    end

    def customers
      realm.with_authenticated_request do |access_token|
        service = Quickbooks::Service::Customer.new(company_id: realm.company_id, access_token: access_token)
        service.query()
      end
    end

  end
end
