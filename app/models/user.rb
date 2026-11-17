class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :proposals, dependent: :nullify
  has_many :posts, dependent: :nullify
  has_many :stored_files, dependent: :destroy
  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile, update_only: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, uniqueness: true

  # Roles: viewer (default) < editor < owner
  # viewer: can view content
  # editor: can view and edit content
  # owner: full administrative access
  enum :role, { viewer: 0, editor: 1, owner: 2 }, default: :viewer

  # Case-insensitive match on email address or profile name.
  scope :search, ->(term) {
    pattern = "%#{sanitize_sql_like(term.to_s.downcase)}%"
    left_joins(:profile).where("LOWER(users.email_address) LIKE :pattern OR LOWER(profiles.name) LIKE :pattern", pattern: pattern)
  }

  # Identifies a user to Flipper so a flag can be on for named people.
  def flipper_id
    "User;#{id}"
  end

  def can_edit?
    editor? || owner?
  end

  def can_manage?
    owner?
  end

  def has_active_membership?
    memberships.active.exists? && !memberships.active.first.associate?
  end

  # Why the user cannot book a space, worded for them to act on. Nil when they can.
  def booking_membership_problem
    return if has_active_membership?

    expired = memberships.lapsed.order(expires_on: :desc).first
    if expired
      "You can't book a space: your annual membership expired on #{expired.expires_on.strftime('%-d %B %Y')}. Pay the annual membership fee to book again."
    else
      "You can't book a space: booking needs a paid annual membership, and you haven't paid one yet."
    end
  end

  def name
    return unless approved?

    profile&.name || email_address.split("@").first
  end
end
