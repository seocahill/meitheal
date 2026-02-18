class CreateProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :proposals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :funding_opportunity, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.datetime :submitted_at
      t.datetime :reviewed_at
      t.text :admin_notes

      t.timestamps

      t.index [:user_id, :funding_opportunity_id], unique: true
    end
  end
end
