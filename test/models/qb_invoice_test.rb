require 'test_helper'

class QbInvoiceTest < ActiveSupport::TestCase
  test 'can create an invoice from order' do
    order = create_effective_order!()

    invoice = Effective::QbInvoiceTool.new.create_qb_invoice!(order: order)
    assert invoice.valid?

    assert_equal invoice.order, order

    order.order_items.each do |order_item|
      assert invoice.qb_invoice_item(order_item: order_item)&.persisted?
    end

    assert_equal 'ready', invoice.status
  end
end
