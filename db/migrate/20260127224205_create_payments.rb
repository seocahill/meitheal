class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :membership, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.date :paid_on, null: false
      t.integer :payment_method, null: false
      t.text :notes

      t.timestamps
    end
  end
end
