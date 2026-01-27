class Membership < ApplicationRecord
  belongs_to :user
  has_many :payments, dependent: :destroy

  enum :membership_type, { standard: 0, concession: 1 }

  validates :membership_type, presence: true
  validates :starts_on, presence: true

  scope :active, -> {
    where("starts_on <= ? AND (expires_on IS NULL OR expires_on >= ?)", Date.current, Date.current)
  }

  def expired?
    expires_on.present? && expires_on < Date.current
  end
end
