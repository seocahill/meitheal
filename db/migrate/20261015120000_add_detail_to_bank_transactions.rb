class AddDetailToBankTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :bank_transactions, :transaction_type, :string, null: false, default: ""
    add_column :bank_transactions, :payment_reference, :string, null: false, default: ""
  end
end
