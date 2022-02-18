module Effective
  class QbSalesReceipt

    # Build the Quickbooks SalesReceipt from a QbReceipt
    def self.build_from_receipt!(receipt, api: nil)
      raise('Expected a persisted Effective::QbReceipt') unless receipt.kind_of?(Effective::QbReceipt) && receipt.persisted?

      api ||= EffectiveQbOnline.api
      raise('Expected a connected Quickbooks API') unless api.present?

      order = receipt.order
      raise('Expected a purchased Effective::Order') unless order.purchased?

      user = order.user
      raise('Expected a user with an email') unless user.respond_to?(:email)

      realm = api.realm
      raise('Missing Deposit to Account') unless realm.deposit_to_account_id.present?
      raise('Missing Payment Method') unless realm.payment_method_id.present?

      taxes = api.taxes_collection
      raise("Missing Tax Code for tax rate #{order.tax_rate.presence || 'blank'}") unless taxes[order.tax_rate.to_s].present?
      raise("Missing Tax Code for tax exempt 0.0 rate") unless taxes['0.0'].present?

      # Find and validate items
      items = api.items()

      receipt.qb_receipt_items.each do |receipt_item|
        purchasable = receipt_item.order_item.purchasable
        raise("Expected a purchasable for Effective::OrderItem #{receipt_item.order_item.id}") unless purchasable.present?

        # Find item by receipt item
        item = items.find { |item| [item.id, item.name].include?(receipt_item.item_id) }

        # Find item by purchasable qb_item_id and qb_item_name
        item ||= begin
          purchasable_id_name = [purchasable.try(:qb_item_id), purchasable.try(:qb_item_name)]
          items.find { |item| ([item.id, item.name] & purchasable_id_name).present? }
        end

        if item.blank?
          raise("Unknown Quickbooks Item for #{purchasable} (#{purchasable.class.name} ##{purchasable.id})")
        end

        receipt_item.update!(item_id: item.id)
      end

      # Find or build customer
      if receipt.customer_id.blank?
        customer = api.find_or_create_customer(user: user)
        receipt.update!(customer_id: customer.id)
      end

      # Receipt
      sales_receipt = Quickbooks::Model::SalesReceipt.new(
        customer_id: receipt.customer_id,
        deposit_to_account_id: api.realm.deposit_to_account_id,   # The ID of the Account Entity you want hte SalesReceipt to be deposited to
        payment_method_id: api.realm.payment_method_id,           # The ID of the PaymentMethod Entity
        payment_ref_number: order.to_param,                       # Optional payment reference number/string
        txn_date: order.purchased_at.to_date,
        customer_memo: order.note_to_buyer,
        private_note: order.note_internal,
        bill_email: Quickbooks::Model::EmailAddress.new(order.email),
        email_status: 'EmailSent'
      )

      # Allows Quickbooks to auto-generate the transaction number
      sales_receipt.auto_doc_number!

      # Addresses
      sales_receipt.bill_address = api.build_address(order.billing_address) if order.billing_address.present?
      sales_receipt.ship_address = api.build_address(order.shipping_address) if order.shipping_address.present?

      # Line Items
      tax_code = taxes[order.tax_rate.to_s]
      tax_exempt = taxes['0.0']

      receipt.qb_receipt_items.each do |receipt_item|
        order_item = receipt_item.order_item
        line_item = Quickbooks::Model::Line.new(amount: api.price_to_amount(order_item.subtotal), description: order_item.name)

        line_item.sales_item! do |line|
          line.item_id = receipt_item.item_id
          line.tax_code_id = (order_item.tax_exempt? ? tax_exempt.id : tax_code.id)

          line.unit_price = api.price_to_amount(order_item.price)
          line.quantity = order_item.quantity
        end

        sales_receipt.line_items << line_item
      end

      # Double check
      raise("Invalid SalesReceipt generated for Effective::Order #{order.id}") unless sales_receipt.valid?

      # Return a Quickbooks::Model::SalesReceipt that is ready to create
      sales_receipt
    end

  end
end
