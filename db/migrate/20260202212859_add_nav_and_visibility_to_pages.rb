class AddNavAndVisibilityToPages < ActiveRecord::Migration[8.1]
  def up
    # Add new columns with defaults
    # nav_location: 0=none, 1=nav, 2=footer, 3=dropdown
    add_column :pages, :nav_location, :integer, default: 0, null: false

    # visibility: 0=draft, 1=published, 2=members_only
    add_column :pages, :visibility, :integer, default: 0, null: false

    # Migrate existing published boolean to visibility enum
    execute <<-SQL
      UPDATE pages SET visibility = CASE WHEN published = 1 THEN 1 ELSE 0 END
    SQL

    # Remove old published column
    remove_column :pages, :published
  end

  def down
    add_column :pages, :published, :boolean, default: false, null: false

    execute <<-SQL
      UPDATE pages SET published = CASE WHEN visibility = 1 THEN 1 ELSE 0 END
    SQL

    remove_column :pages, :visibility
    remove_column :pages, :nav_location
  end
end
