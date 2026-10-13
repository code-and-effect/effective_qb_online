$:.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'effective_qb_online/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'effective_qb_online'
  spec.version     = EffectiveQbOnline::VERSION
  spec.authors     = ['Code and Effect']
  spec.email       = ['info@codeandeffect.com']
  spec.homepage    = 'https://github.com/code-and-effect/effective_qb_online'
  spec.summary     = 'Create QuickBooks Online SalesReceipts for purchased effective orders'
  spec.description = 'Create QuickBooks Online SalesReceipts for purchased effective orders'
  spec.license     = 'MIT'

  spec.files = Dir["{app,config,db,lib}/**/*"] + ['MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'rails', '>= 6.0.0'
  spec.add_dependency 'quickbooks-ruby', '~> 2.0', '>= 2.0.7'
  spec.add_dependency 'oauth2', '~> 2.0', '>= 2.0.25'
  spec.add_dependency 'faraday', '~> 2.14', '>= 2.14.4'
  spec.add_dependency 'faraday-net_http_persistent', '~> 2.3', '>= 2.3.1'
  spec.add_dependency 'effective_bootstrap'
  spec.add_dependency 'effective_datatables'
  spec.add_dependency 'effective_orders'
  spec.add_dependency 'effective_resources'

  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'devise'
  spec.add_development_dependency 'dotenv-rails'
  spec.add_development_dependency 'haml-rails'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'wicked'
  spec.add_development_dependency 'effective_test_bot'
  spec.add_development_dependency 'effective_developer'
end
