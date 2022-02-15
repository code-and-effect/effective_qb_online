class CreateEffectiveQbOnline < ActiveRecord::Migration[6.1]
  def change
    create_table :qb_realms do |t|
      t.string :realm_id

      t.text :access_token
      t.datetime :access_token_expires_at

      t.text :refresh_token
      t.datetime :refresh_token_expires_at

      t.timestamps
    end
  end
end
