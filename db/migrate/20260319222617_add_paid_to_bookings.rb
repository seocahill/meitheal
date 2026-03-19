class AddPaidToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :paid, :boolean, default: false, null: false

    # Backfill existing bookings as paid (assume historical bookings were settled)
    reversible do |dir|
      dir.up do
        Booking.update_all(paid: true)
      end
    end
  end
end
