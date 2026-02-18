class CreateEmailArchives < ActiveRecord::Migration[8.1]
  def change
    create_table :email_archives do |t|
      t.string :message_id, null: false
      t.string :folder_id
      t.datetime :archived_at, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end
    add_index :email_archives, :message_id, unique: true
  end
end
