EffectiveQbOnline.setup do |config|
  config.qb_realms_table_name = :qb_realms
  config.qb_receipts_table_name = :qb_receipts
  config.qb_receipt_items_table_name = :qb_receipt_items

  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  # Quickbooks Online Application
  # Client and Seceret
  config.oauth_client_id = ENV['QUICKBOOKS_ONLINE_OAUTH_CLIENT_ID']
  config.oauth_client_secret = ENV['QUICKBOOKS_ONLINE_OAUTH_CLIENT_SECRET']

  # Quickbooks API
  # https://github.com/ruckus/quickbooks-ruby
  Quickbooks.sandbox_mode = (ENV['QUICKBOOKS_ONLINE_SANDBOX'].to_s == 'true')

  # Effective Orders
  # Add the following to your config/intializers/effective_orders.rb
  # config.use_effective_qb_online = true

end
