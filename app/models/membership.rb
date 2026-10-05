class Membership < ApplicationRecord
  belongs_to :user
  has_many :payments, dependent: :destroy

  enum :membership_type, { associate: 0, concession: 1, full: 2, youth: 3 }

  # Annual contribution in cents. Associates pay nothing.
  FEE_CENTS = { youth: 500, concession: 1000, full: 2000 }.freeze
  RENEWAL_WINDOW = 30.days

  validates :membership_type, presence: true
  validates :starts_on, presence: true

  scope :active, -> {
    where("starts_on <= ? AND (expires_on IS NULL OR expires_on >= ?)", Date.current, Date.current)
  }

  # Payment status of fee-paying memberships. A payment sets expires_on a year
  # ahead, so no expiry means no payment has been recorded.
  scope :fee_paying, -> { where.not(membership_type: :associate) }
  scope :no_fee, -> { where(membership_type: :associate) }
  scope :paid, -> { fee_paying.where("expires_on >= ?", Date.current) }
  scope :lapsed, -> { fee_paying.where("expires_on < ?", Date.current) }
  scope :unpaid, -> { fee_paying.where(expires_on: nil) }
  scope :renewing_soon, -> { paid.where(expires_on: ..(Date.current + RENEWAL_WINDOW)) }

  def expired?
    expires_on.present? && expires_on < Date.current
  end

  def payment_status
    return :no_fee if associate?
    return :unpaid if expires_on.nil?

    expired? ? :lapsed : :paid
  end

  # Records an offline payment (cash, bank transfer, ...) and renews the
  # membership for a year from today.
  def record_payment!(payment_method:)
    raise ArgumentError, "associate memberships have no fee" if associate?

    transaction do
      payments.create!(
        amount_cents: FEE_CENTS.fetch(membership_type.to_sym),
        paid_on: Date.current,
        payment_method: payment_method,
        purpose: :membership,
        status: :completed,
        user_email: user.email_address,
        user_name: user.profile&.name.presence || user.email_address,
        description: "NCF #{membership_type.humanize} Membership"
      )
      update!(expires_on: Date.current + 1.year)
    end
  end

  # Corrects a payment recorded in error. Payments stay on file.
  def mark_unpaid!
    update!(expires_on: nil)
  end
end
