class AddBookingToPayments < ActiveRecord::Migration[8.1]
  def change
    add_reference :payments, :booking, foreign_key: true
  end
end
