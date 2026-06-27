class AddTicketingToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :ticketing_enabled, :boolean, default: false, null: false
    add_column :events, :tickets_available_from, :datetime
  end
end
