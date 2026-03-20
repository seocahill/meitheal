class AddStatusToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :status, :integer, default: 0, null: false
    add_index :payments, :status
  end
end
