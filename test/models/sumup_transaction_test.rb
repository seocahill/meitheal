require "test_helper"

class SumupTransactionTest < ActiveSupport::TestCase
  def transaction(sumup_id, **attrs)
    SumupTransaction.create!({
      sumup_id: sumup_id, transaction_id: sumup_id, amount_cents: 2000, occurred_at: Time.utc(2026, 10, 1, 10),
      kind: "PAYMENT", status: "SUCCESSFUL"
    }.merge(attrs))
  end

  setup do
    Payment.where.not(sumup_transaction_id: nil).update_all(sumup_transaction_id: nil)
    Ticket.where.not(sumup_transaction_id: nil).update_all(sumup_transaction_id: nil)
  end

  test "sumup_id is unique" do
    transaction("abc")

    assert_raises(ActiveRecord::RecordNotUnique) { transaction("abc") }
  end

  test "unmatched is a successful payment with no payment or ticket carrying its id" do
    known_by_payment = transaction("paid-id")
    known_by_ticket = transaction("ticket-id")
    unknown = transaction("reader-id")
    memberships(:active_membership).payments.create!(
      amount_cents: 2000, paid_on: Date.current, payment_method: :sumup, sumup_transaction_id: "paid-id",
      user_email: "a@example.com", user_name: "A", description: "Fee"
    )
    Ticket.create!(event: Event.first, buyer_name: "B", buyer_email: "b@example.com", quantity: 1,
                   amount_cents: 1000, status: :paid, sumup_transaction_id: "ticket-id")

    assert_equal [ unknown ], SumupTransaction.unmatched.to_a
    assert_not_includes SumupTransaction.unmatched, known_by_payment
    assert_not_includes SumupTransaction.unmatched, known_by_ticket
  end

  test "unmatched also matches on the transaction_id SumUp reports, not just its id" do
    transaction("history-id", transaction_id: "checkout-txn-id")
    memberships(:active_membership).payments.create!(
      amount_cents: 2000, paid_on: Date.current, payment_method: :sumup, sumup_transaction_id: "checkout-txn-id",
      user_email: "a@example.com", user_name: "A", description: "Fee"
    )

    assert_empty SumupTransaction.unmatched
  end

  test "unmatched with no transaction_id still lists the transaction" do
    unknown = transaction("no-txn-id", transaction_id: nil)

    assert_equal [ unknown ], SumupTransaction.unmatched.to_a
  end

  test "unmatched leaves out failed, refunded and non-payment transactions" do
    transaction("failed", status: "FAILED")
    transaction("refunded", status: "REFUNDED")
    transaction("refund-row", kind: "REFUND")

    assert_empty SumupTransaction.unmatched
  end
end
