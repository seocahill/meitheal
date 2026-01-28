class EmailGroupMembership < ApplicationRecord
  belongs_to :email_group
  belongs_to :user

  validates :user_id, uniqueness: { scope: :email_group_id }
end
