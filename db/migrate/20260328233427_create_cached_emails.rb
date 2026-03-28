class CreateCachedEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :cached_emails do |t|
      t.string :zoho_message_id, null: false
      t.string :zoho_folder_id, null: false
      t.string :from_address, null: false
      t.string :subject, null: false
      t.text :summary
      t.text :body
      t.datetime :received_at, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end
    add_index :cached_emails, :zoho_message_id, unique: true
    add_index :cached_emails, :received_at

    drop_table :email_archives
  end
end
