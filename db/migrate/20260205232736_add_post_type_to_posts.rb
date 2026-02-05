class AddPostTypeToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :post_type, :integer, default: 0, null: false
  end
end
