class AddApprovedToFundingOpportunities < ActiveRecord::Migration[8.1]
  def change
    add_column :funding_opportunities, :approved, :boolean, default: false, null: false
  end
end
