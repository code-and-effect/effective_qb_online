require 'test_helper'

class QbReceiptTest < ActiveSupport::TestCase
  test 'can create an receipt from order' do
    order = create_effective_order!()

    receipt = Effective::QbReceiptTool.new.create_qb_receipt!(order: order)
    assert receipt.valid?

    assert_equal receipt.order, order

    order.order_items.each do |order_item|
      assert receipt.qb_receipt_item(order_item: order_item)&.persisted?
    end

    assert_equal 'ready', receipt.status
  end
end
