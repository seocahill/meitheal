class AddApprovalFieldsToBookings < ActiveRecord::Migration[8.1]
  def change
    add_reference :bookings, :approved_by, null: true, foreign_key: { to_table: :users }
    add_column :bookings, :approved_at, :datetime
  end
end
