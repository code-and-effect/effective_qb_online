require 'test_helper'

class QbEffctiveOrdersTest < ActiveSupport::TestCase

  test 'purchasing an effective order syncs with Quickbooks' do
    api = EffectiveQbOnline.api
    items = api.items().reject { |item| item.type == 'Category' }

    # Create a new order with valid Qb Item Names
    order = create_effective_order!()
    order.purchasables.first.update!(qb_item_name: items.sample.id)
    order.purchasables.last.update!(qb_item_name: items.sample.name)

    # Purchase the Order
    Effective::Order.transaction { order.purchase! }

    qb_receipt = Effective::QbReceipt.where(order: order).first
    assert qb_receipt.present?

    assert qb_receipt.completed?
    assert qb_receipt.sales_receipt_id.present?
  end

end
