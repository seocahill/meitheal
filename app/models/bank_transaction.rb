# A line of the SumUp Business Account statement, kept so money received by bank transfer
# can be matched to the payments recorded here.
class BankTransaction < ApplicationRecord
  belongs_to :bank_import
  belongs_to :payment, optional: true

  validates :code, :occurred_on, :amount_cents, presence: true

  # Money received that no payment accounts for, newest first. SumUp's own payouts of card
  # takings are left out: they are the sum of sales the SumUp transaction history lists one
  # by one.
  scope :unmatched, -> {
    where(payment_id: nil)
      .where("amount_cents > 0")
      .where.not("reference LIKE 'SUMUP PID%' OR reference LIKE 'PID %'")
      .order(occurred_on: :desc, id: :desc)
  }

  def self.latest_date
    maximum(:occurred_on)
  end
end
