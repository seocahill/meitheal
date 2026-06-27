class Ticket < ApplicationRecord
  belongs_to :event

  enum :status, { pending: 0, paid: 1, failed: 2 }

  validates :buyer_name, presence: true
  validates :buyer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :quantity, numericality: { greater_than: 0 }
  validates :amount_cents, numericality: { greater_than: 0 }
end
