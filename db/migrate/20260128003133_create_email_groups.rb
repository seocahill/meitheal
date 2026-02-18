class CreateEmailGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :email_groups do |t|
      t.string :name, null: false
      t.string :local_part, null: false
      t.text :description
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :email_groups, :local_part, unique: true
  end
end
