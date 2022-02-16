require 'test_helper'

class QbSalesReceiptTest < ActiveSupport::TestCase

  test 'can sync a sales receipt from receipt' do
    order = create_effective_order!()
    order.purchase!

    api = EffectiveQbOnline.api
    receipt = Effective::QbReceipt.create_from_order!(order)

    sales_receipt = Effective::QbSalesReceipt.build_from_receipt!(receipt, api: api)
    assert sales_receipt.valid?

    sales_receipt = api.create_sales_receipt(sales_receipt: sales_receipt)
    puts "Created: #{api.sales_receipt_url(sales_receipt)}"

    assert sales_receipt.id.present?
  end

end
