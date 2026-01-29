class AddSumupFieldsToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :sumup_checkout_id, :string
    add_column :payments, :sumup_transaction_id, :string
  end
end
