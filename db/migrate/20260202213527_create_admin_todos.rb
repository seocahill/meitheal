class CreateAdminTodos < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_todos do |t|
      t.string :title, null: false
      t.text :description
      t.boolean :completed, default: false, null: false
      t.date :due_date
      t.integer :priority, default: 0, null: false
      t.integer :position
      t.references :source, polymorphic: true, index: true

      t.timestamps
    end

    add_index :admin_todos, :completed
    add_index :admin_todos, :due_date
    add_index :admin_todos, :position
  end
end
