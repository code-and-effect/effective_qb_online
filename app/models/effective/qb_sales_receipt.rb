module Effective
  class QbSalesReceipt

    # Build the QuickBooks SalesReceipt from a QbReceipt
    def self.build_from_receipt!(receipt, api: nil)
      raise('Expected a persisted Effective::QbReceipt') unless receipt.kind_of?(Effective::QbReceipt) && receipt.persisted?

      api ||= EffectiveQbOnline.api
      raise('Expected a connected QuickBooks API') unless api.present?

      order = receipt.order
      raise('Expected a purchased Effective::Order') unless order.purchased?
      raise('Expected an order with billing name') unless order.billing_name.present?

      realm = api.realm
      raise('Missing Deposit to Account') unless realm.deposit_to_account_id.present?
      raise('Missing Payment Method') unless realm.payment_method_id.present?

      taxes = api.taxes_collection
      raise("Missing Tax Code for tax rate #{order.tax_rate.presence || 'blank'}") unless taxes[order.tax_rate.to_s].present?
      raise("Missing Tax Code for tax exempt 0.0 rate") unless taxes['0.0'].present?

      # Find and validate items
      items = api.items()

      # Credit card surcharge item
      surcharge_item = if EffectiveOrders.try(:credit_card_surcharge_qb_item_name).present?
        name = EffectiveOrders.credit_card_surcharge_qb_item_name

        item = items.find do |item|
          [scrub(item.id), scrub(item.name), scrub(item.fully_qualified_name)].include?(scrub(name))
        end

        raise("Missing Credit Card Surcharge item #{name}. Please add this to your Quickbooks items.") unless item.present?

        item
      end

      receipt.qb_receipt_items.each do |receipt_item|
        purchasable = receipt_item.order_item.purchasable
        raise("Expected a purchasable for Effective::OrderItem #{receipt_item.order_item.id}") unless purchasable.present?

        # Either of these could match
        purchasable_id_name = [
          (scrub(purchasable.qb_item_id) if purchasable.try(:qb_item_id)),
          (scrub(purchasable.qb_item_name) if purchasable.try(:qb_item_name))
        ].compact

        # Find item by receipt item
        item = items.find do |item|
          [scrub(item.id), scrub(item.name), scrub(item.fully_qualified_name)].include?(scrub(receipt_item.item_id))
        end

        # Find item by purchasable qb_item_id and qb_item_name
        item ||= items.find do |item|
          ([scrub(item.id), scrub(item.name), scrub(item.fully_qualified_name)] & purchasable_id_name).present?
        end

        if item.blank?
          purchasable_id_name = [purchasable.try(:qb_item_id), purchasable.try(:qb_item_name)].compact
          raise("Unknown Item #{purchasable_id_name.join(' or ')} from #{purchasable} (#{purchasable.class.name} ##{purchasable.id})")
        end

        receipt_item.update!(item_id: item.id)
      end

      # Find or build customer
      if receipt.customer_id.blank?
        customer = api.find_or_create_customer(order: order)
        receipt.update!(customer_id: customer.id)
      end

      doc_number = (order.to_param if api.realm.order_number_as_transaction_number?)

      # Receipt
      sales_receipt = Quickbooks::Model::SalesReceipt.new(
        customer_id: receipt.customer_id,
        deposit_to_account_id: api.realm.deposit_to_account_id,   # The ID of the Account Entity you want the SalesReceipt to be deposited to
        payment_method_id: api.realm.payment_method_id,           # The ID of the PaymentMethod Entity
        doc_number: doc_number,                                   # This is the transaction # field
        payment_ref_number: order.to_param,                       # Optional payment reference number/string
        txn_date: order.purchased_at.to_date,
        customer_memo: order.note_to_buyer,
        private_note: order.note_internal,
        bill_email: Quickbooks::Model::EmailAddress.new(order.email),
        email_status: 'EmailSent'
      )

      # Allows QuickBooks to auto-generate the transaction number
      sales_receipt.auto_doc_number! if doc_number.blank?

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

      # Add Credit Card Surcharge
      if order.try(:surcharge).to_i != 0
        raise("Expected a Credit Card Surcharge QuickBooks item to exist for Effective::Order #{order.id} with non-zero surcharge amount. Please check your configuration.") unless surcharge_item.present?

        line_item = Quickbooks::Model::Line.new(amount: api.price_to_amount(order.surcharge), description: 'Credit Card Surcharge')

        line_item.sales_item! do |line|
          line.item_id = surcharge_item.id
          line.tax_code_id = tax_code.id  # Surcharge is taxed at same rate as items

          line.unit_price = api.price_to_amount(order.surcharge)
          line.quantity = 1
        end

        sales_receipt.line_items << line_item
      end

      # Double check
      raise("Invalid SalesReceipt generated for Effective::Order #{order.id}") unless sales_receipt.valid?

      # Return a Quickbooks::Model::SalesReceipt that is ready to create
      sales_receipt
    end

    private

    def self.scrub(value)
      value.to_s.downcase.strip
    end

  end
end
