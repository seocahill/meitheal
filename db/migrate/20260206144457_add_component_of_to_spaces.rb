class AddComponentOfToSpaces < ActiveRecord::Migration[8.1]
  def change
    add_reference :spaces, :component_of, foreign_key: { to_table: :spaces }

    reversible do |dir|
      dir.up do
        Space.reset_column_information

        Space.where(name: "Main Hall").update_all(name: "Front Room")
        Space.where(name: "Studio").update_all(name: "Back Room")

        whole_building = Space.create!(name: "Whole Building", description: "Entire building including Front Room and Back Room", active: true)
        Space.where(name: ["Front Room", "Back Room"]).update_all(component_of_id: whole_building.id)
      end
    end
  end
end
