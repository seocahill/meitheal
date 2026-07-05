class AllowNullUserOnPostsAndProposals < ActiveRecord::Migration[8.1]
  def change
    # posts and proposals use dependent: :nullify so user_id must be nullable
    change_column_null :posts, :user_id, true
    change_column_null :proposals, :user_id, true
  end
end
