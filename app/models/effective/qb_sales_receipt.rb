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

      # Find and validate receipt items
      items = api.items()

      receipt.qb_receipt_items.each do |receipt_item|
        # Match item by receipt item
        item = items.find { |item| [item.id, item.name].include?(receipt_item.item_id) }

        if item.present?
          receipt_item.update!(item_id: item.id); next
        end

        # Match item by order_item purchasable
        purchasable = receipt_item.order_item.purchasable
        raise("expecting purchasable for order item #{receipt_item.order_item.id}") if purchasable.blank?

        item = items.find do |item|
          ([item.id, item.name] & [purchsable.try(:qb_item_id), purchasable.try(:qb_item_name)]).present?
        end

        if item.present?
          receipt_item.update!(item_id: item.id); next
        end

      end


      # Receipt
      sales_receipt = Quickbooks::Model::SalesReceipt.new(
        customer_id: receipt.customer_id,
        txn_date: order.purchased_at.to_date,
        payment_ref_number: order.to_param,                       # Optional payment reference number/string
        deposit_to_account_id: api.realm.deposit_to_account_id,   # The ID of the Account Entity you want hte SalesReceipt to be deposited to
        payment_method_id: api.realm.payment_method_id,           # The ID of the PaymentMethod Entity
        bill_email: Quickbooks::Model::EmailAddress.new(order.email),
        customer_memo: order.note_to_buyer,
        private_note: order.note_internal
      )

      # Allows Quicbooks to auto-generate the transaction number
      sales_receipt.auto_doc_number!

      # Addresses
      sales_receipt.bill_address = build_address(order.billing_address) if order.billing_address.present?
      sales_receipt.ship_address = build_address(order.shipping_address) if order.shipping_address.present?

      # Line Items
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

    private

    def self.build_address(address)
      raise('Expected a Effective::Address') unless address.kind_of?(Effective::Address)

      Quickbooks::Model::PhysicalAddress.new(
        line1: address.address1,
        line2: address.address2,
        line3: address.try(:address3),
        city: address.city,
        country: address.country,
        country_sub_division_code: address.country_code,
        postal_code: address.postal_code
      )
    end

  end
end
