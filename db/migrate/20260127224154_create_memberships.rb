class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :membership_type, null: false
      t.date :starts_on, null: false
      t.date :expires_on
      t.text :notes

      t.timestamps
    end
  end
end
