class EmailGroup < ApplicationRecord
  has_many :email_group_memberships, dependent: :destroy
  has_many :members, through: :email_group_memberships, source: :user
  has_many :archived_emails, dependent: :destroy

  validates :name, presence: true
  validates :local_part, presence: true, uniqueness: true
  validates :local_part, format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }

  scope :active, -> { where(active: true) }

  # Domain for email addresses
  DOMAIN = "thencf.art".freeze

  def email_address
    "#{local_part}@#{DOMAIN}"
  end

  def add_member(user)
    email_group_memberships.find_or_create_by!(user: user)
  end
end
