class AddBrevoCampaignIdToNewsletters < ActiveRecord::Migration[8.1]
  def change
    add_column :newsletters, :brevo_campaign_id, :integer
  end
end
