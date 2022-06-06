EffectiveOrders.setup do |config|
  # Configure Database Tables
  config.orders_table_name = :orders
  config.order_items_table_name = :order_items
  config.carts_table_name = :carts
  config.cart_items_table_name = :cart_items
  config.customers_table_name = :customers
  config.subscriptions_table_name = :subscriptions
  config.products_table_name = :products

  # Layout Settings
  # config.layout = { application: 'application', admin: 'admin' }

  # Filter the @orders on admin/orders#index screen
  # config.orders_collection_scope = Proc.new { |scope| scope.where(...) }

  # Require these addresses when creating a new Order.  Works with effective_addresses gem
  config.billing_address = true
  config.shipping_address = false

  # Use effective_obfuscation gem to change order.id into a seemingly random 10-digit number
  config.obfuscate_order_ids = false

  # Effective QuickBooks Synchronization
  config.use_effective_qb_sync = false
  config.use_effective_qb_online = true

  # If set, the orders#new screen will render effective/orders/_order_note_fields to capture any Note info
  config.collect_note = false
  config.collect_note_required = false
  config.collect_note_message = ''

  # If true, the orders#new screen will render effective/orders/_terms_and_conditions_fields to require a Terms of Service boolean
  # config.terms_and_conditions_label can be a String or a Proc
  # config.terms_and_conditions_label = Proc.new { |order| "Yes, I agree to the #{link_to 'terms and conditions', terms_and_conditions_path}." }
  config.terms_and_conditions = false
  config.terms_and_conditions_label = 'I agree to the terms and conditions.'

  # Tax Calculation Method
  # The Effective::TaxRateCalculator considers the order.billing_address and assigns a tax based on country & state code
  # Right now, only Canadian provinces are supported. Sorry.
  # To always charge 12.5% tax: Proc.new { |order| 12.5 }
  # To always charge 0% tax: Proc.new { |order| 0 }
  # If the Proc returns nil, the tax rate will be calculated once again whenever the order is validated
  # An order must have a tax rate (even if the value is 0) to be purchased
  config.order_tax_rate_method = Proc.new { |order| Effective::TaxRateCalculator.new(order: order).tax_rate }

  # Minimum Charge
  # Prevent orders less than this value from being purchased
  # Stripe doesn't allow orders less than $0.50
  # Set to nil for no minimum charge
  # Default value is 50 cents, or $0.50
  config.minimum_charge = 50

  # Free Orders
  # Allow orders with a total of 0.00 to be purchased (regardless of the minimum charge setting)
  config.free_enabled = true

  # Mark as Paid
  # Mark an order as paid without going through a processor
  # This is accessed via the admin screens only. Must have can?(:admin, :effective_orders)
  config.mark_as_paid_enabled = false

  # Pretend Purchase
  # Display a 'Purchase order' button on the Checkout screen allowing the user
  # to purchase an Order without going through the payment processor.
  # WARNING: Setting this option to true will allow users to purchase! an Order without entering a credit card
  # WARNING: When true, users can purchase! anything without paying money
  config.pretend_enabled = !Rails.env.production?
  config.pretend_message = '* payment information is not required to process this order at this time.'

  # Mailer Settings
  # Please see config/initializers/effective_resources.rb for default effective_* gem mailer settings
  #
  # Configure the class responsible to send e-mails.
  # config.mailer = 'Effective::OrdersMailer'
  #
  # Override effective_resource mailer defaults
  #
  # config.parent_mailer = nil      # The parent class responsible for sending emails
  # config.deliver_method = nil     # The deliver method, deliver_later or deliver_now
  # config.mailer_layout = nil      # Default mailer layout
  # config.mailer_sender = nil      # Default From value
  # config.mailer_admin = nil       # Default To value for Admin correspondence
  # config.mailer_subject = nil     # Proc.new method used to customize Subject

  config.mailer_layout = 'effective_orders_mailer_layout'

  # Email settings
  config.send_order_receipt_to_admin = true
  config.send_order_receipt_to_buyer = true
  config.send_payment_request_to_buyer = true
  config.send_pending_order_invoice_to_buyer = true

  config.send_order_receipts_when_mark_as_paid = true
  config.send_order_receipts_when_free = true

  # Stripe Webhooks controller
  config.send_subscription_events = true

  # These two only take affect if you schedule the rake task to run
  config.send_subscription_trialing = true
  config.send_subscription_trial_expired = true


end
