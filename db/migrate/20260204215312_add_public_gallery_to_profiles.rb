class AddPublicGalleryToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :public_gallery, :boolean, default: false, null: false
  end
end
