require 'test_helper'
require_relative '../../db/migrate/20261013140000_upgrade_effective_qb_online_zero_nine_twelve'

class QbUpgradeMigrationTest < ActiveSupport::TestCase
  class MigrationRecord < ActiveRecord::Base
    self.abstract_class = true
  end

  test 'upgrade is idempotent and rollback removes only the recovery columns' do
    MigrationRecord.establish_connection(adapter: 'sqlite3', database: ':memory:')
    connection = MigrationRecord.connection
    connection.create_table(:qb_realms) { |table| table.string :realm_id }
    connection.execute("INSERT INTO qb_realms (realm_id) VALUES ('original-company')")
    migration = UpgradeEffectiveQbOnlineZeroNineTwelve.new
    migration.define_singleton_method(:connection) { connection }
    migration.suppress_messages do
      migration.up
      migration.up
      assert connection.column_exists?(:qb_realms, :reconnection_required_at)
      assert connection.column_exists?(:qb_realms, :reconnection_reason)
      migration.down
      migration.down
      refute connection.column_exists?(:qb_realms, :reconnection_required_at)
      refute connection.column_exists?(:qb_realms, :reconnection_reason)
      assert_equal 'original-company', connection.select_value('SELECT realm_id FROM qb_realms')
    end
  ensure
    MigrationRecord.remove_connection
  end
end
