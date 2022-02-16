module Effective
  class QbReceiptTool

    # Create a QbReceipt and QbReceiptItems from an Effective::Order
    def create_qb_receipt!(order:)
      raise('expected an Effective::Order') unless order.kind_of?(Effective::Order)

      qb_receipt = Effective::QbReceipt.where(order: order).first_or_initialize

      order.order_items.each do |order_item|
        qb_receipt_item = qb_receipt.qb_receipt_item(order_item: order_item)

        item_id = order_item.purchasable.try(:qb_item_id)
        item_name = order_item.purchasable.try(:qb_item_name)

        if item_id.blank? && item_name.present?
          item_id = api.item(name: item_name)&.id
        end

        qb_receipt_item.assign_attributes(item_id: item_id)
      end

      qb_receipt.save!
      qb_receipt
    end

    # Synchronize a QbReceipt with Quickbooks
    def sync_qb_receipt!(receipt:)
      sales_receipt = build_qb_receipt(receipt: receipt)
      api.create_sales_receipt(sales_receipt: sales_receipt)
    end

    def build_qb_receipt(receipt:)
      raise('expected a persisted Effective::QbReceipt') unless receipt.kind_of?(Effective::QbReceipt) && receipt.persisted?

      order = receipt.order
      raise('expected a purchased Effective::Order') unless order.purchased?

      customer_id = receipt.customer_id

      sales_receipt = Quickbooks::Model::SalesReceipt.new(
        customer_id: receipt.customer_id,
        txn_date: order.purchased_at.to_date,
        payment_ref_number: order.to_param,                       # Optional payment reference number/string
        deposit_to_account_id: api.realm.deposit_to_account_id,   # The ID of the Account Entity you want hte SalesReceipt to be deposited to
        payment_method_id: api.realm.payment_method_id,           # The ID of the PaymentMethod Entity
      )

      # Allows Quicbooks to auto-generate the transaction number
      sales_receipt.auto_doc_number!

      # Add all the line items
      order.order_items.each do |order_item|
        line_item = Quickbooks::Model::Line.new(
          amount: order_item.subtotal,
          description: order_item.name
        )

        line_item.sales_item! do |line|
          line.unit_price = order_item.price
          line.quantity = order_item.quantity
          line.item_id = order_item.quickbooks_item_id
        end

        sales_receipt.line_items << line_item
      end

      sales_receipt
    end

    private

    def api
      @api ||= EffectiveQbOnline.api
    end

    def deposit_to_account_id
    end

  end
end
