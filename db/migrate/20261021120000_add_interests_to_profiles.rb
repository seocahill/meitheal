class AddInterestsToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :interests, :string
  end
end
