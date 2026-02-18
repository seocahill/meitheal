class CreateArchivedEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :archived_emails do |t|
      t.references :email_group, null: false, foreign_key: true
      t.string :from_address, null: false
      t.string :subject, null: false
      t.text :body
      t.datetime :received_at, null: false

      t.timestamps
    end

    add_index :archived_emails, :received_at
  end
end
