class UpgradeEffectiveQbOnlineZeroNineTwelve < ActiveRecord::Migration[6.0]
  def change
    unless column_exists?(:qb_realms, :reconnection_required_at)
      add_column :qb_realms, :reconnection_required_at, :datetime
    end

    unless column_exists?(:qb_realms, :reconnection_reason)
      add_column :qb_realms, :reconnection_reason, :string
    end
  end
end
