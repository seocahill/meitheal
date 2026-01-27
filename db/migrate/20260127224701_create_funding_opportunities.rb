class CreateFundingOpportunities < ActiveRecord::Migration[8.1]
  def change
    create_table :funding_opportunities do |t|
      t.string :title, null: false
      t.string :organization, null: false
      t.text :description
      t.date :deadline, null: false
      t.integer :amount
      t.string :url
      t.string :categories

      t.timestamps
    end

    add_index :funding_opportunities, :deadline
  end
end
