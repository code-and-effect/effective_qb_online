module Effective
  class QbSalesReceipt

    # Build the Quickbooks SalesReceipt from a QbReceipt
    def self.build_from_receipt!(receipt, api: nil)
      raise('expected a persisted Effective::QbReceipt') unless receipt.kind_of?(Effective::QbReceipt) && receipt.persisted?

      api ||= EffectiveQbOnline.api
      raise('expected a connected Quickbooks API') unless api.present?

      order = receipt.order
      raise('expected a purchased Effective::Order') unless order.purchased?

      user = order.user
      raise('expected a user with an email') unless user.respond_to?(:email)

      realm = api.realm
      raise('missing Deposit to Account') unless realm.deposit_to_account_id.present?
      raise('missing Payment Method') unless realm.payment_method_id.present?

      # Find or build customer
      if receipt.customer_id.blank?
        customer = api.find_or_create_customer(user: user)
        receipt.update!(customer_id: customer.id)
      end

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
      receipt.qb_receipt_items.each do |receipt_item|
        order_item = receipt_item.order_item

        line_item = Quickbooks::Model::Line.new(
          amount: (order_item.subtotal / 100.0).round(2),
          description: order_item.name
        )

        line_item.sales_item! do |line|
          line.unit_price = (order_item.price / 100.0).round(2)
          line.quantity = order_item.quantity

          # This comes from the Receipt Item so we can change it.
          line.item_id = receipt_item.item_id
        end

        sales_receipt.line_items << line_item
      end

      sales_receipt
    end

  end
end
