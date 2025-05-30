# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

if ENV['QB_REALM_ID'].blank?
  require "dotenv/load"
end

require 'haml'
require 'effective_orders'

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path('../db/migrate', __dir__)
require "rails/test_help"

# Filter out the backtrace from minitest while preserving the one from other libraries.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
  ActiveSupport::TestCase.fixtures :all
end

# Custom Test Helpers
require 'support/effective_qb_online_test_builder'
require 'support/effective_qb_online_test_helper'
require 'support/effective_orders_test_builder'
require 'pry-byebug'

class ActiveSupport::TestCase
  include Warden::Test::Helpers

  include EffectiveOrdersTestBuilder

  include EffectiveQbOnlineTestBuilder
  include EffectiveQbOnlineTestHelper
end

# QuickBooks Online Specific Stuff
Quickbooks.sandbox_mode = true

# Load the seeds
load "#{__dir__}/../db/seeds.rb"
load "#{__dir__}/fixtures/realm.rb"
