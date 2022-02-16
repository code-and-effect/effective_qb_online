require 'test_helper'

class QbReceiptTest < ActiveSupport::TestCase

  test 'can create an receipt from order' do
    tool = Effective::QbReceiptTool.new
    order = create_effective_order!()

    receipt = tool.create_qb_receipt!(order: order)
    assert receipt.valid?

    assert_equal receipt.order, order

    order.order_items.each do |order_item|
      assert receipt.qb_receipt_item(order_item: order_item)&.persisted?
    end

    assert_equal 'ready', receipt.status

    assert receipt.customer_id.blank?
    assert receipt.qb_receipt_items.all? { |item| item.item_id.blank? }
  end

  test 'can build a sales receipt from receipt' do
    tool = Effective::QbReceiptTool.new

    order = create_effective_order!()
    order.purchase!

    receipt = tool.create_qb_receipt!(order: order)

    sales_receipt = tool.build_qb_receipt(receipt: receipt)


  end

end
