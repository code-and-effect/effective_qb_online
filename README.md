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
