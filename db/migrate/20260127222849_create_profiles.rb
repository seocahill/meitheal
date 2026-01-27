class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :name, null: false
      t.text :bio
      t.string :skills
      t.string :website
      t.string :location
      t.boolean :visible, default: true, null: false

      t.timestamps
    end
  end
end
