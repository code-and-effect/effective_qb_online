require 'test_helper'

class QbApiTest < ActiveSupport::TestCase
  test 'the api is connected' do
    assert EffectiveQbOnline.api.present?
  end

  test 'company info' do
    company_info = EffectiveQbOnline.api.company_info

    assert_equal 'Sandbox Company_CA_2', company_info.company_name
    assert_equal 'CA', company_info.country
  end

  test 'can crud customers' do
    now = Time.zone.now.to_i

    user = build_user()
    user.update!(email: "user-#{now}@example.com", first_name: "Test User", last_name: "#{now}")

    customer = EffectiveQbOnline.api.find_customer(user: user)
    assert customer.blank?

    customer = EffectiveQbOnline.api.create_customer(user: user)
    assert customer.present?

    assert_equal customer.primary_email_address.address, user.email
    assert_equal customer.given_name, user.first_name
    assert_equal customer.family_name, user.last_name

    assert EffectiveQbOnline.api.delete_customer(customer: customer)

    customer = EffectiveQbOnline.api.find_customer(user: user)
    assert customer.blank?
  end

end
