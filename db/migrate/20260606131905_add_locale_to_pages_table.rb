class AddLocaleToPagesTable < ActiveRecord::Migration[8.1]
  def change
    add_column :pages, :locale, :string, null: false, default: "en"

    remove_index :pages, :slug
    add_index :pages, [ :slug, :locale ], unique: true
  end
end
