class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :events, dependent: :nullify
  has_many :bookings, dependent: :nullify
  has_many :memberships, dependent: :destroy
  has_many :email_group_memberships, dependent: :destroy
  has_many :email_groups, through: :email_group_memberships
  has_many :proposals, dependent: :destroy
  has_one :profile, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Roles: viewer (default) < editor < owner
  # viewer: can view content
  # editor: can view and edit content
  # owner: full administrative access
  enum :role, { viewer: 0, editor: 1, owner: 2 }, default: :viewer

  def can_edit?
    editor? || owner?
  end

  def can_manage?
    owner?
  end
end
