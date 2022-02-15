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
  spec.summary     = 'Synchronize your effective orders with Quickbooks Online'
  spec.description = 'Synchronize your effective orders with Quickbooks Online'
  spec.license     = 'MIT'

  spec.files = Dir["{app,config,db,lib}/**/*"] + ['MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'rails', '>= 6.0.0'
  spec.add_dependency 'quickbooks-ruby'
  spec.add_dependency 'effective_bootstrap'
  spec.add_dependency 'effective_datatables'
  spec.add_dependency 'effective_orders'
  spec.add_dependency 'effective_resources'

  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'devise'
  spec.add_development_dependency 'dotenv-rails'
  spec.add_development_dependency 'haml-rails'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'effective_test_bot'
  spec.add_development_dependency 'effective_developer' # Optional but suggested
end
