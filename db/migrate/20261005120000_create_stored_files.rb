class CreateStoredFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :stored_files do |t|
      t.references :user, null: false, foreign_key: true
      t.string :description

      t.timestamps
    end
    add_index :stored_files, :created_at
  end
end
