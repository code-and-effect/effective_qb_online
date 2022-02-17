module Effective
  class QbSalesReceipt

    # Build the Quickbooks SalesReceipt from a QbReceipt
    def self.build_from_receipt!(receipt, api: nil)
      raise('expected a persisted Effective::QbReceipt') unless receipt.kind_of?(Effective::QbReceipt) && receipt.persisted?

      api ||= EffectiveQbOnline.api
      raise('expected a connected Quickbooks API') unless api.present?

      company_info = api.company_info
      raise('expected a Canadian CA Quickbooks Company') unless company_info.country == 'CA'

      order = receipt.order
      raise('expected a purchased Effective::Order') unless order.purchased?

      user = order.user
      raise('expected a user with an email') unless user.respond_to?(:email)

      realm = api.realm
      raise('missing Deposit to Account') unless realm.deposit_to_account_id.present?
      raise('missing Payment Method') unless realm.payment_method_id.present?

      # Find or build quickbooks customer
      if receipt.customer_id.blank?
        customer = api.find_or_create_customer(user: user)
        receipt.update!(customer_id: customer.id)
      end

      # Find and validate quickbooks items
      items = api.items()

      receipt.qb_receipt_items.each do |receipt_item|
        purchasable = receipt_item.order_item.purchasable
        raise("expected a purchasable for Effective::OrderItem #{receipt_item.order_item.id}") unless purchasable.present?

        # Match item by receipt item
        item = items.find { |item| [item.id, item.name].include?(receipt_item.item_id) }

        # Match item by purchasable qb_item_id and qb_item_name
        item ||= begin
          purchasable_id_name = [purchasable.try(:qb_item_id), purchasable.try(:qb_item_name)]
          items.find { |item| ([item.id, item.name] & purchasable_id_name).present? }
        end

        if item.blank?
          raise("unknown Quickbooks Item for #{purchasable} (#{purchasable.class.name} ##{purchasable.id} qb_item_id=#{purchasable.try(:qb_item_id) || 'blank'} qb_item_name=#{purchasable.try(:qb_item_name) || 'blank'})")
        end

        receipt_item.update!(item_id: item.id)
      end

      # Receipt
      sales_receipt = Quickbooks::Model::SalesReceipt.new(
        customer_id: receipt.customer_id,
        txn_date: order.purchased_at.to_date,
        payment_ref_number: order.to_param,                       # Optional payment reference number/string
        deposit_to_account_id: api.realm.deposit_to_account_id,   # The ID of the Account Entity you want hte SalesReceipt to be deposited to
        payment_method_id: api.realm.payment_method_id,           # The ID of the PaymentMethod Entity
        customer_memo: order.note_to_buyer,
        private_note: order.note_internal,
        bill_email: qb_email(order.email),
        email_status: 'EmailSent'
      )

      # Allows Quicbooks to auto-generate the transaction number
      sales_receipt.auto_doc_number!

      # Addresses
      sales_receipt.bill_address = qb_address(order.billing_address) if order.billing_address.present?
      sales_receipt.ship_address = qb_address(order.shipping_address) if order.shipping_address.present?

      # Line Items
      receipt.qb_receipt_items.each do |receipt_item|
        order_item = receipt_item.order_item
        line_item = Quickbooks::Model::Line.new(amount: qb_price(order_item.subtotal), description: order_item.name)

        line_item.sales_item! do |line|
          line.item_id = receipt_item.item_id

          line.unit_price = qb_price(order_item.price)
          line.quantity = order_item.quantity
        end

        sales_receipt.line_items << line_item
      end

      # Taxes
      taxes = api.taxes

      binding.pry

      sales_receipt.txn_tax_detail = Quickbooks::Model::TransactionTaxDetail.new(
        txn_tax_code_id: 13,
        total_tax: qb_price(order.tax)
      )

      sales_receipt
    end

    private

    def self.qb_price(price)
      raise('Expected an Integer price') unless price.kind_of?(Integer)
      (price / 100.0).round(2)
    end

    def self.qb_email(email)
      raise('Expected an String email') unless email.kind_of?(String)
      Quickbooks::Model::EmailAddress.new(email)
    end

    def self.qb_address(address)
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
