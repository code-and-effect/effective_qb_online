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

  # Sync Error Email
  # When a sync error occurs, an email is sent to the following addresses:
  # EffectiveOrders.qb_online_sync_error_recipients or EffectiveOrders.mailer_admin
  # You can also specify a list of additional recipients to be cc'd on the email by setting:
  # config.sync_error_cc_recipients = ['"Errors" <errors@example.com>']

  # Mailer Settings
  # Please see config/initializers/effective_resources.rb for default effective_* gem mailer settings
  #
  # Configure the class responsible to send e-mails.
  # config.mailer = 'Effective::QbOnlineMailer'
  #
  # Override effective_resource mailer defaults
  #
  # config.parent_mailer = nil      # The parent class responsible for sending emails
  # config.deliver_method = nil     # The deliver method, deliver_later or deliver_now
  # config.mailer_layout = nil      # Default mailer layout
  # config.mailer_sender = nil      # Default From value
  # config.mailer_admin = nil       # Default To value for Admin correspondence
  # config.mailer_subject = nil     # Proc.new method used to customize Subject
end
