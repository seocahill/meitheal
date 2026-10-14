# A transaction as SumUp reports it, kept so card takings can be reconciled
# against the payments and tickets recorded here.
class SumupTransaction < ApplicationRecord
  validates :sumup_id, :amount_cents, :occurred_at, presence: true

  # Successful payments that no Payment or Ticket accounts for, such as card
  # reader sales or checkouts that were paid but never recorded. A payment or
  # ticket may hold either of the ids SumUp reports.
  scope :unmatched, -> {
    known = "SELECT sumup_transaction_id FROM payments WHERE sumup_transaction_id IS NOT NULL " \
            "UNION SELECT sumup_transaction_id FROM tickets WHERE sumup_transaction_id IS NOT NULL"
    where(status: "SUCCESSFUL", kind: "PAYMENT")
      .where("sumup_id NOT IN (#{known})")
      .where("transaction_id IS NULL OR transaction_id NOT IN (#{known})")
  }
end
