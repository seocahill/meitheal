class AddPendingMembershipTypeToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :pending_membership_type, :string
  end
end
