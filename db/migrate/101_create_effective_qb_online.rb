class CreateEffectiveQbOnline < ActiveRecord::Migration[6.0]
  def change
    create_table :qb_realms do |t|
      t.string :realm_id

      t.integer :deposit_to_account_id
      t.integer :payment_method_id
      t.boolean :order_number_as_transaction_number, default: false

      t.text :access_token
      t.datetime :access_token_expires_at

      t.text :refresh_token
      t.datetime :refresh_token_expires_at

      t.timestamps
    end

    create_table :qb_receipts do |t|
      t.integer :order_id
      t.integer :customer_id

      t.text :result

      t.string :status
      t.text :status_steps

      t.timestamps
    end

    add_index :qb_receipts, :order_id

    create_table :qb_receipt_items_name do |t|
      t.integer :qb_receipt_id
      t.integer :order_item_id

      t.integer :item_id

      t.timestamps
    end

  end
end
