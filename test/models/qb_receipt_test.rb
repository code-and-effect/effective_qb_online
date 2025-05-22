require 'test_helper'

class QbReceiptTest < ActiveSupport::TestCase

  test 'can create an receipt from order' do
    order = create_effective_order!()
    order.purchase!

    Effective::QbReceipt.delete_all

    receipt = Effective::QbReceipt.create_from_order!(order)
    assert receipt.valid?

    assert_equal receipt.order, order

    order.order_items.each do |order_item|
      assert receipt.qb_receipt_item(order_item: order_item)&.persisted?
    end

    assert_equal 'todo', receipt.status

    assert receipt.customer_id.blank?
    assert receipt.qb_receipt_items.all? { |item| item.item_id.blank? }
  end

  test 'sends an error email if the receipt cannot be synced' do
    order = create_effective_order!()
    order.purchase!

    Effective::QbReceipt.delete_all

    receipt = Effective::QbReceipt.create_from_order!(order)

    assert_email do
      receipt.assign_attributes(result: 'test error')
      receipt.error!
    end
  end
end
