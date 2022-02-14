EffectiveQbOnline.setup do |config|
  # config.resource_table_name = :resources

  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }


  config.oauth_client_id = ENV['QUICKBOOKS_ONLINE_OAUTH_CLIENT_ID']
  config.oauth_client_secret = ENV['QUICKBOOKS_ONLINE_OAUTH_CLIENT_SECRET']

  Quickbooks.sandbox_mode = ENV['QUICKBOOKS_ONLINE_SANDBOX']
end
