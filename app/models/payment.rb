class Payment < ApplicationRecord
  belongs_to :membership

  enum :payment_method, { cash: 0, bank_transfer: 1, other: 2, sumup: 3 }

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :paid_on, presence: true
  validates :payment_method, presence: true
  validates :user_email, presence: true
  validates :user_name, presence: true
  validates :description, presence: true

  scope :recent, -> { where("paid_on >= ?", 30.days.ago) }
  scope :by_payment_method, ->(method) { where(payment_method: method) if method.present? }
  scope :by_date_range, ->(start_date, end_date) {
    where(paid_on: start_date..end_date) if start_date.present? && end_date.present?
  }
  scope :search, ->(term) {
    where("LOWER(user_email) LIKE LOWER(?) OR LOWER(user_name) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?)",
          "%#{sanitize_sql_like(term)}%", "%#{sanitize_sql_like(term)}%", "%#{sanitize_sql_like(term)}%") if term.present?
  }

  def amount_euro
    amount_cents / 100.0
  end
end
