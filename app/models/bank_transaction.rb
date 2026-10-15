# A line of the SumUp Business Account statement, kept so money received by bank transfer
# can be matched to the payments recorded here.
class BankTransaction < ApplicationRecord
  belongs_to :bank_import
  belongs_to :payment, optional: true

  validates :code, :occurred_on, :amount_cents, presence: true

  SUMUP_PAYOUT = "SumUp pay-in".freeze

  # Money received that no payment accounts for, newest first. SumUp's own payouts of card
  # takings are left out: they are the sum of sales the SumUp transaction history lists one
  # by one.
  scope :unmatched, -> {
    where(payment_id: nil)
      .where("amount_cents > 0")
      .where.not(transaction_type: SUMUP_PAYOUT)
      .order(occurred_on: :desc, id: :desc)
  }

  # Matches the reference and what the payer wrote against the transfer.
  scope :search, ->(term) {
    next if term.blank?

    pattern = "%#{sanitize_sql_like(term.strip.downcase)}%"
    where("LOWER(reference) LIKE :t ESCAPE '\\' OR LOWER(payment_reference) LIKE :t ESCAPE '\\'", t: pattern)
  }
  scope :by_type, ->(type) { where(transaction_type: type) if type.present? }
  scope :by_direction, ->(direction) {
    case direction
    when "in" then where("amount_cents > 0")
    when "out" then where("amount_cents < 0")
    end
  }
  scope :by_match, ->(match) {
    case match
    when "matched" then where.not(payment_id: nil)
    when "unmatched" then where(payment_id: nil)
    end
  }
  scope :by_date_range, ->(start_date, end_date) {
    where(occurred_on: start_date..end_date) if start_date.present? || end_date.present?
  }

  def self.types
    where.not(transaction_type: "").distinct.order(:transaction_type).pluck(:transaction_type)
  end

  def self.latest_date
    maximum(:occurred_on)
  end
end
