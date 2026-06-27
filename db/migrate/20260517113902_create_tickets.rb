class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.references :event, null: false, foreign_key: true
      t.string :buyer_name, null: false
      t.string :buyer_email, null: false
      t.integer :quantity, null: false, default: 1
      t.integer :amount_cents, null: false
      t.integer :status, null: false, default: 0
      t.string :sumup_checkout_id
      t.string :sumup_transaction_id

      t.timestamps
    end

    add_index :tickets, :sumup_checkout_id
    add_index :tickets, :status
  end
end
