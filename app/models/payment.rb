class Payment < ApplicationRecord
  belongs_to :membership

  enum :payment_method, { cash: 0, bank_transfer: 1, other: 2, sumup: 3 }

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :paid_on, presence: true
  validates :payment_method, presence: true

  scope :recent, -> { where("paid_on >= ?", 30.days.ago) }

  def amount_euro
    amount_cents / 100.0
  end
end
