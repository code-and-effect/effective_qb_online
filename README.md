# Effective QuickBooks Online

Create QuickBooks Online SalesReceipts for purchased effective orders. This is an unofficial integration that is not supported by or affiliated with Intuit.

## Getting Started

This requires Rails 6+ and Twitter Bootstrap 4 and just works with Devise.

Please first install the [effective_datatables](https://github.com/code-and-effect/effective_datatables) gem.

Please download and install the [Twitter Bootstrap4](http://getbootstrap.com)

Add to your Gemfile:

```ruby
gem 'haml-rails' # or try using gem 'hamlit-rails'
gem 'effective_qb_online'
```

Run the bundle command to install it:

```console
bundle install
```

Then run the generator:

```ruby
rails generate effective_qb_online:install
```

The generator will install an initializer which describes all configuration options and creates a database migration.

If you want to tweak the table names, manually adjust both the configuration file and the migration now.

Then migrate the database:

```ruby
rake db:migrate
```

```
Add a link to the admin menu:

```haml
- if can? :admin, :effective_qb_online
  = nav_link_to 'QuickBooks Online', effective_qb_online.admin_quickbooks_path
```

and visit `/admin/quickbooks`.

## Authorization

All authorization checks are handled via the effective_resources gem found in the `config/initializers/effective_resources.rb` file.

## Permissions

The permissions you actually want to define are as follows (using CanCan):

```ruby
if user.admin?
  can :admin, :effective_qb_online

  can(crud, Effective::QbRealm)
  can(crud + [:skip, :sync], Effective::QbReceipt) { |receipt| !receipt.completed? }
end
```

## Configuring QuickBooks Company

This gem has only been tested with Canadian Quickbooks Online stores.

It has GST, HST and Tax Exempt tax codes and rates set up ahead of time by QuickBooks.

## License

MIT License. Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

## Testing

There are tests, but the access token and refresh token doesn't work well.

You must visit /admin/quickbooks and copy & paste the test credentials into ~/.env

```ruby
rails test
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request

## OAuth recovery (0.9.12)

Existing installations must copy `db/migrate/20261013140000_upgrade_effective_qb_online_zero_nine_twelve.rb`
into the host application's migrations and migrate before loading 0.9.12. New installations receive
these columns through the install generator. Keep the existing company account settings when reconnecting.

A terminal `invalid_grant` during refresh records a reconnection-required state and sends one
notice to the configured QuickBooks sync error recipients (falling back to the orders admin).
Notification uses the shared mailer delivery/error handling and is best-effort: a delivery
failure is reported, but does not unpause the connection or trigger repeated notices.
The administrator page always exposes the recovery action while paused.
Subsequent API attempts stop locally until an administrator reconnects. Other errors, including
network timeouts, throttling, provider outages, and invalid client configuration, retain their
normal error handling. Errored receipts remain available for manual admin retry; reconnection
never retries them automatically.

OAuth clients are isolated per request/API instance. Revocation uses the OAuth2 client's
`revoke_token` API with client Basic authentication and a JSON body at Intuit's absolute endpoint.
Refreshes serialize token rotation and store the provider's refresh-token lifetime when supplied.
Authorization callbacks validate and consume the session's OAuth state.

References:

- [Intuit OAuth 2.0 developer documentation](https://developer.intuit.com/app/developer/qbo/docs/develop/authentication-and-authorization/oauth-2.0)
- [Intuit production discovery document](https://developer.intuit.com/.well-known/openid_configuration)
- [Intuit OAuth SDK request formats](https://github.com/intuit/oauth-jsclient/blob/master/src/OAuthClient.js)
- [OAuth2 client API](https://github.com/ruby-oauth/oauth2/blob/v2.0.25/lib/oauth2/client.rb)

The QuickBooks/OAuth transport dependencies are tested with quickbooks-ruby 2.0.7,
oauth2 2.0.25, Faraday 2.14.4, faraday-gzip 3.2.0, faraday-net_http_persistent 2.3.1,
and net-http-persistent 4.0.8. Only this dependency group was updated.

Offline recovery checks (no Intuit credentials or network calls required):

```console
RAILS_ENV=test mise exec -- bin/rails db:migrate
mise exec -- bin/rails test test/models/qb_oauth_recovery_test.rb
```

The older sandbox API tests require live sandbox credentials; do not use production credentials.
