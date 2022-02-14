EffectiveQbOnline.setup do |config|
  # config.resource_table_name = :resources

  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  config.oauth_client_id = 'ABTdC8s2eMDVhotCM0qX29S0TUwtTiBQDEh2eApZuZOS6z6J60'
  config.oauth_client_secret = 's8fC4jjzXiawpNZsIMg5ezbDLcDdFY1T2MGxjrUT'

  Quickbooks.sandbox_mode = true
end
