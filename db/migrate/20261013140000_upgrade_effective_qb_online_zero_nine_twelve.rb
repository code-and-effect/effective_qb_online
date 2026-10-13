class UpgradeEffectiveQbOnlineZeroNineTwelve < ActiveRecord::Migration[6.0]
  def up
    add_column :qb_realms, :reconnection_required_at, :datetime unless column_exists?(:qb_realms, :reconnection_required_at)
    add_column :qb_realms, :reconnection_reason, :string unless column_exists?(:qb_realms, :reconnection_reason)
  end

  def down
    remove_column :qb_realms, :reconnection_reason if column_exists?(:qb_realms, :reconnection_reason)
    remove_column :qb_realms, :reconnection_required_at if column_exists?(:qb_realms, :reconnection_required_at)
  end
end
