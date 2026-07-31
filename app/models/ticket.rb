class Ticket < ApplicationRecord
  belongs_to :event

  # reserved: a booking added by an editor for someone paying at the door.
  # It holds a seat (counts toward capacity) but is not online revenue.
  enum :status, { pending: 0, paid: 1, failed: 2, reserved: 3 }

  # Tickets are guest purchases keyed by email, not linked to a user account,
  # so a member's tickets are found by matching their account email.
  scope :for_email, ->(email) { where("lower(buyer_email) = ?", email.to_s.strip.downcase) }

  validates :buyer_name, presence: true
  validates :buyer_email, presence: true, unless: :reserved?
  validates :buyer_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :amount_cents, numericality: { greater_than: 0 }
end
