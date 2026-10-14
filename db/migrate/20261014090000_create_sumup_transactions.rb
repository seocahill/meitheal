class CreateSumupTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :sumup_transactions do |t|
      t.string :sumup_id, null: false
      t.string :transaction_id
      t.string :transaction_code
      t.string :kind
      t.string :status
      t.string :payment_type
      t.integer :amount_cents, null: false
      t.string :currency
      t.string :product_summary
      t.datetime :occurred_at, null: false

      t.timestamps
    end
    add_index :sumup_transactions, :sumup_id, unique: true
    add_index :sumup_transactions, :occurred_at
  end
end
