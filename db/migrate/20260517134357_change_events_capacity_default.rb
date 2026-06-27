class ChangeEventsCapacityDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :events, :capacity, from: nil, to: 50
  end
end
