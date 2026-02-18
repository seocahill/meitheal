class CreateNewsletters < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletters do |t|
      t.string :subject, null: false
      t.integer :status, default: 0, null: false
      t.datetime :sent_at
      t.references :chat, null: true, foreign_key: true

      t.timestamps
    end
  end
end
