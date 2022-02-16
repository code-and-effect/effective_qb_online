require 'test_helper'

class QbSalesReceiptTest < ActiveSupport::TestCase

  test 'can build a sales receipt from receipt' do
    order = create_effective_order!()
    order.purchase!

    receipt = Effective::QbReceipt.create_from_order!(order: order)

    sales_receipt = Effective::QbSalesReceipt.new.build_sales_receipt(receipt: receipt)
    assert sales_receipt.valid?

  end

end
