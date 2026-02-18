class CreateEmailGroupMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :email_group_memberships do |t|
      t.references :email_group, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :email_group_memberships, [ :email_group_id, :user_id ], unique: true
  end
end
