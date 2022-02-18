require 'test_helper'

class QbSalesReceiptTest < ActiveSupport::TestCase

  test 'can sync a sales receipt from receipt' do
    order = create_effective_order!()
    order.update!(note_to_buyer: 'Note to Buyer', note_internal: 'Note Internal')
    order.mark_as_purchased!

    api = EffectiveQbOnline.api
    receipt = Effective::QbReceipt.create_from_order!(order)
    assert receipt.qb_receipt_items.all? { |receipt_item| receipt_item.item_id.blank? }

    # Assign valid Item ids to all receipt items
    items = api.items().reject { |item| item.type == 'Category' }
    order.purchasables.first.update!(qb_item_name: items.sample.id)
    order.purchasables.last.update!(qb_item_name: items.sample.name)

    # Build Sales Receipt - Assigns all items
    sales_receipt = Effective::QbSalesReceipt.build_from_receipt!(receipt, api: api)
    assert sales_receipt.valid?
    assert receipt.qb_receipt_items.all? { |receipt_item| receipt_item.item_id.present? }

    # Actually create it with Quickbooks
    sales_receipt = api.create_sales_receipt(sales_receipt: sales_receipt)
    puts "Created: #{api.sales_receipt_url(sales_receipt)}"

    # The Sales Receipt is persisted
    assert sales_receipt.id.present?

    # Customer matches
    assert_equal receipt.customer_id, sales_receipt.customer_ref.value

    # Emails match
    assert_equal order.email, sales_receipt.bill_email.address
    assert_equal 'EmailSent', sales_receipt.email_status

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

    # Deposit matches
    assert_equal api.realm.deposit_to_account_id, sales_receipt.deposit_to_account_ref.value
    assert_equal 0.0, sales_receipt.balance

    # Items match
    taxes = api.taxes_collection
    tax_code = taxes[order.tax_rate.to_s]
    tax_exempt = taxes['0.0']

    order.order_items.each do |order_item|
      line = sales_receipt.line_items.find { |line| line.description == order_item.name }
      assert(line.present?, 'missing sales item line for order item')

      assert_equal (order_item.subtotal / 100.0).round(2), line.amount

      if order_item.tax_exempt?
        assert_equal line.sales_item_line_detail.tax_code_ref.value, tax_exempt.id
      else
        assert_equal line.sales_item_line_detail.tax_code_ref.value, tax_code.id
      end
    end

    # Totals match
    assert_equal (order.total / 100.0).round(2), sales_receipt.total
    assert_equal (order.tax / 100.0).round(2), sales_receipt.txn_tax_detail.total_tax
  end

end
