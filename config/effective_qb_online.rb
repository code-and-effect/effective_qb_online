EffectiveQbOnline.setup do |config|
  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  # QuickBooks Online Application
  # Client and Seceret
  config.oauth_client_id = ENV['QUICKBOOKS_ONLINE_OAUTH_CLIENT_ID']
  config.oauth_client_secret = ENV['QUICKBOOKS_ONLINE_OAUTH_CLIENT_SECRET']

  # QuickBooks API
  # https://github.com/ruckus/quickbooks-ruby
  Quickbooks.sandbox_mode = (ENV['QUICKBOOKS_ONLINE_SANDBOX'].to_s == 'true')

  # Effective Orders
  # Add the following to your config/intializers/effective_orders.rb
  # config.use_effective_qb_online = true

end
