class AddBoxOfficeToEventsAndTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :checked_in_count, :integer, default: 0, null: false
    add_column :events, :audience_left_count, :integer, default: 0, null: false
    add_column :events, :box_office_closed_manually, :boolean, default: false, null: false
  end
end
