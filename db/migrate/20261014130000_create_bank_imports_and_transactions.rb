class CreateBankImportsAndTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :bank_imports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :filename, null: false
      t.integer :rows_read, null: false
      t.integer :rows_added, null: false

      t.timestamps
    end

    create_table :bank_transactions do |t|
      t.references :bank_import, null: false, foreign_key: true
      t.references :payment, foreign_key: true
      t.string :code, null: false
      t.date :occurred_on, null: false
      t.string :reference, null: false, default: ""
      t.integer :amount_cents, null: false

      t.timestamps
    end
    add_index :bank_transactions, :code, unique: true
    add_index :bank_transactions, :occurred_on
  end
end
