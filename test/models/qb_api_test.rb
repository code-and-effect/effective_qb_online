require 'test_helper'

class QbApiTest < ActiveSupport::TestCase
  # test 'the api is connected' do
  #   api = EffectiveQbOnline.api
  #   assert api.present?
  #   assert api.realm.present?
  # end

  test 'can list customers' do
    assert EffectiveQbOnline.api.customers.count > 0
  end

end
