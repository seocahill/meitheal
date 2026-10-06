class Payment < ApplicationRecord
  belongs_to :membership

  enum :payment_method, { cash: 0, bank_transfer: 1, other: 2, sumup: 3 }
  enum :purpose, { membership: 0, booking: 1, donation: 2, other_purpose: 3 }
  enum :status, { completed: 0, pending: 1, failed: 2 }

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :paid_on, presence: true
  validates :payment_method, presence: true
  validates :user_email, presence: true
  validates :user_name, presence: true
  validates :description, presence: true

  scope :recent, -> { where("paid_on >= ?", 30.days.ago) }
  scope :by_payment_method, ->(method) { where(payment_method: method) if method.present? }
  scope :by_purpose, ->(purpose) { where(purpose: purpose) if purpose.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }
  # Either bound may be nil for an open ended range.
  scope :by_date_range, ->(start_date, end_date) {
    where(paid_on: start_date..end_date) if start_date.present? || end_date.present?
  }
  # Matches the details copied onto the payment, and the member's current name or email.
  scope :search, ->(term) {
    next if term.blank?

    pattern = "%#{sanitize_sql_like(term.downcase)}%"
    member_ids = Membership.joins(:user).left_joins(user: :profile)
                           .where("LOWER(users.email_address) LIKE :t OR LOWER(profiles.name) LIKE :t", t: pattern)
                           .select(:id)
    where("LOWER(payments.user_email) LIKE :t OR LOWER(payments.user_name) LIKE :t OR LOWER(payments.description) LIKE :t", t: pattern)
      .or(where(membership_id: member_ids))
  }

  def amount_euro
    amount_cents / 100.0
  end
end
