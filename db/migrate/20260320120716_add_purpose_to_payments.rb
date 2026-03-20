class AddPurposeToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :purpose, :integer, default: 0, null: false
  end
end
