require 'test_helper'

class QbSalesReceiptTest < ActiveSupport::TestCase

  test 'can sync a sales receipt from receipt' do
    order = create_effective_order!()
    order.update!(note_to_buyer: 'Note to Buyer', note_internal: 'Note Internal')
    order.purchase!

    assert order.billing_address.present?
    assert order.shipping_address.present?

    api = EffectiveQbOnline.api
    receipt = Effective::QbReceipt.create_from_order!(order)

    sales_receipt = Effective::QbSalesReceipt.build_from_receipt!(receipt, api: api)
    assert sales_receipt.valid?

    sales_receipt = api.create_sales_receipt(sales_receipt: sales_receipt)
    puts "Created: #{api.sales_receipt_url(sales_receipt)}"

    # The Sales Receipt is persisted
    assert sales_receipt.id.present?

    # Details match
    assert_equal order.email, sales_receipt.bill_email.address

    # Addresses match
    assert_equal order.billing_address.address1, sales_receipt.bill_address.line1
    assert_equal order.billing_address.address2, sales_receipt.bill_address.line2
    assert_equal order.billing_address.city, sales_receipt.bill_address.city
    assert_equal order.billing_address.country, sales_receipt.bill_address.country
    assert_equal order.billing_address.country_code, sales_receipt.bill_address.country_sub_division_code
    assert_equal order.billing_address.postal_code, sales_receipt.bill_address.postal_code

    assert_equal order.shipping_address.address1, sales_receipt.ship_address.line1
    assert_equal order.shipping_address.address2, sales_receipt.ship_address.line2
    assert_equal order.shipping_address.city, sales_receipt.ship_address.city
    assert_equal order.shipping_address.country, sales_receipt.ship_address.country
    assert_equal order.shipping_address.country_code, sales_receipt.ship_address.country_sub_division_code
    assert_equal order.shipping_address.postal_code, sales_receipt.ship_address.postal_code

    # Notes match
    assert_equal order.note_to_buyer, sales_receipt.customer_memo
    assert_equal order.note_internal, sales_receipt.private_note
  end

end
