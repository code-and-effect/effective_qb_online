class CreateEffectiveQbOnline < ActiveRecord::Migration[6.0]
  def change
    create_table :qb_realms, if_not_exists: true do |t|
      t.string :realm_id

      t.string :deposit_to_account_id
      t.string :payment_method_id

      t.text :access_token
      t.datetime :access_token_expires_at

      t.text :refresh_token
      t.datetime :refresh_token_expires_at

      t.boolean :order_number_as_transaction_number, default: false

      t.timestamps
    end

    create_table :qb_receipts, if_not_exists: true do |t|
      t.integer :order_id

      t.string :customer_id
      t.string :sales_receipt_id

      t.text :result

      t.string :status
      t.text :status_steps

      t.timestamps
    end

    add_index :qb_receipts, :order_id, if_not_exists: true

    create_table :qb_receipt_items, if_not_exists: true do |t|
      t.integer :qb_receipt_id
      t.integer :order_item_id

      t.string :item_id

      t.timestamps
    end

  end
end
