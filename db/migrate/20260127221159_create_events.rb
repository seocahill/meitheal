class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.datetime :doors_at
      t.text :description
      t.text :bio
      t.text :links
      t.integer :ticket_price_cents
      t.string :ticket_url
      t.integer :capacity
      t.string :venue_name
      t.text :venue_address
      t.boolean :published, default: false, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :events, :published
    add_index :events, :starts_at
  end
end
