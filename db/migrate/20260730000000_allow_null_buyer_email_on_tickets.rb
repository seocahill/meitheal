class AllowNullBuyerEmailOnTickets < ActiveRecord::Migration[8.1]
  def change
    change_column_null :tickets, :buyer_email, true
  end
end
