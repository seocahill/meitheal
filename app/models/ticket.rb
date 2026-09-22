class Ticket < ApplicationRecord
  belongs_to :event

  # reserved: a booking added by an editor for someone paying at the door.
  # It holds a seat (counts toward capacity) but is not online revenue.
  enum :status, { pending: 0, paid: 1, failed: 2, reserved: 3 }

  # Tickets are guest purchases keyed by email, not linked to a user account,
  # so a member's tickets are found by matching their account email.
  # Tickets that let someone in the door: paid online or reserved at the door.
  scope :admitted, -> { where(status: [ :paid, :reserved ]) }

  scope :for_email, ->(email) { where("lower(buyer_email) = ?", email.to_s.strip.downcase) }

  validates :buyer_name, presence: true
  validates :buyer_email, presence: true, unless: :reserved?
  validates :buyer_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :amount_cents, numericality: { greater_than: 0 }
  validates :checked_in_count, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: :quantity }

  def admitted?
    paid? || reserved?
  end

  def remaining_to_check_in
    quantity - checked_in_count
  end

  def fully_checked_in?
    remaining_to_check_in == 0
  end

  # Admits `count` people on this ticket, refusing if the ticket doesn't
  # cover them or the room has no space for them.
  def check_in!(count)
    return false unless admitted?
    return false if count < 1 || count > remaining_to_check_in
    space = event.audience_space_left
    return false if space && count > space
    update!(checked_in_count: checked_in_count + count)
  end

  def undo_check_in!
    return if checked_in_count.zero?
    update!(checked_in_count: checked_in_count - 1)
  end
end
