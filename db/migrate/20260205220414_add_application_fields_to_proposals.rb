class AddApplicationFieldsToProposals < ActiveRecord::Migration[8.1]
  def change
    add_column :proposals, :submission_deadline, :date
    add_column :proposals, :amount_requested, :decimal, precision: 10, scale: 2
    add_column :proposals, :organizer_fee, :decimal, precision: 10, scale: 2, default: 0
  end
end
