require 'test_helper'

class QbApiTest < ActiveSupport::TestCase
  test 'the api is connected' do
    assert EffectiveQbOnline.api.present?
  end

  test 'company info' do
    company_info = EffectiveQbOnline.api.company_info

    assert_equal 'Effective Company', company_info.company_name
    assert_equal 'US', company_info.country
  end

  test 'can list customers' do
    assert EffectiveQbOnline.api.customers.count > 0
  end

  test 'can list invoices' do
    assert EffectiveQbOnline.api.invoices.count > 0
  end

  test 'can list customers count' do
    assert EffectiveQbOnline.api.customers_count > 0
  end

  test 'can list invoices count' do
    assert EffectiveQbOnline.api.invoices_count > 0
  end

end
