class CreateFaqs < ActiveRecord::Migration[8.1]
  def change
    create_table :faqs do |t|
      t.string :question, null: false
      t.integer :order
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :faqs, :order
    add_index :faqs, :active
  end
end
