require "test_helper"

class BankTransactionTest < ActiveSupport::TestCase
  setup do
    @import = BankImport.create!(user: users(:editor), filename: "report.csv", rows_read: 0, rows_added: 0)
  end

  def transaction(code, reference: "Somebody", amount_cents: 2000, occurred_on: Date.new(2025, 12, 1), **attrs)
    BankTransaction.create!({ bank_import: @import, code: code, reference: reference, amount_cents: amount_cents, occurred_on: occurred_on }.merge(attrs))
  end

  test "code is unique" do
    transaction("ABC")

    assert_raises(ActiveRecord::RecordNotUnique) { transaction("ABC") }
  end

  test "requires a code, date and amount" do
    assert_not BankTransaction.new(bank_import: @import, occurred_on: Date.current, amount_cents: 1).valid?
    assert_not BankTransaction.new(bank_import: @import, code: "X", amount_cents: 1).valid?
    assert_not BankTransaction.new(bank_import: @import, code: "X", occurred_on: Date.current).valid?
  end

  test "unmatched is money received that no payment accounts for, newest first" do
    older = transaction("OLDER", occurred_on: Date.new(2025, 11, 1))
    newer = transaction("NEWER", occurred_on: Date.new(2025, 12, 1))
    transaction("SPENT", amount_cents: -8325)
    transaction("MATCHED").tap do |matched|
      matched.update!(payment: memberships(:active_membership).payments.create!(
        amount_cents: 2000, paid_on: Date.current, payment_method: :bank_transfer,
        user_email: "a@example.com", user_name: "A", description: "Fee"
      ))
    end

    assert_equal [ newer, older ], BankTransaction.unmatched.to_a
  end

  test "unmatched leaves out SumUp card payouts, which the SumUp transaction history already covers" do
    transaction("PAYOUT1", reference: "SUMUP PID1379801 PAYOUT 171025", transaction_type: "SumUp pay-in")
    transaction("PAYOUT2", reference: "PID 911974", transaction_type: "SumUp pay-in")
    transaction("PAYOUT3", reference: "Settlement 2026-10-01", transaction_type: "SumUp pay-in")
    kept = transaction("TRANSFER", reference: "SUMUP SOCIAL CLUB IE12ABCD12345678901234", transaction_type: "Incoming bank transfer")

    assert_equal [ kept ], BankTransaction.unmatched.to_a
  end

  test "latest_date is the date of the most recent transaction" do
    assert_nil BankTransaction.latest_date
    transaction("A", occurred_on: Date.new(2025, 10, 1))
    transaction("B", occurred_on: Date.new(2025, 12, 30))

    assert_equal Date.new(2025, 12, 30), BankTransaction.latest_date
  end
end
