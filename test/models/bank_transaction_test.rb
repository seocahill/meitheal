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

  test "search matches the reference or the payment reference, ignoring case" do
    by_reference = transaction("A", reference: "JONATHAN FLANAGAN IE42IPBS99073031587381")
    by_note = transaction("B", reference: "Somebody", payment_reference: "Unity Elec for Jonathan")
    transaction("C", reference: "Somebody else", payment_reference: "Gas")

    assert_equal [ by_reference, by_note ].sort_by(&:id), BankTransaction.search("jonathan").sort_by(&:id)
  end

  test "search treats a percent sign as a plain character" do
    literal = transaction("A", payment_reference: "50% deposit")
    transaction("B", payment_reference: "500 deposit")

    assert_equal [ literal ], BankTransaction.search("50%").to_a
  end

  test "a blank search leaves everything in" do
    transaction("A")
    transaction("B")

    assert_equal 2, BankTransaction.search("  ").count
    assert_equal 2, BankTransaction.search(nil).count
  end

  test "by_type keeps one kind of transaction" do
    direct_debit = transaction("A", transaction_type: "Direct debit")
    transaction("B", transaction_type: "SumUp pay-in")

    assert_equal [ direct_debit ], BankTransaction.by_type("Direct debit").to_a
    assert_equal 2, BankTransaction.by_type(nil).count
  end

  test "by_direction separates money received from money paid out" do
    received = transaction("IN", amount_cents: 2000)
    paid = transaction("OUT", amount_cents: -8325)

    assert_equal [ received ], BankTransaction.by_direction("in").to_a
    assert_equal [ paid ], BankTransaction.by_direction("out").to_a
    assert_equal 2, BankTransaction.by_direction(nil).count
  end

  test "by_match separates transactions matched to a payment from those that are not" do
    open = transaction("OPEN")
    matched = transaction("MATCHED")
    matched.update!(payment: memberships(:active_membership).payments.create!(
      amount_cents: 2000, paid_on: Date.current, payment_method: :bank_transfer,
      user_email: "a@example.com", user_name: "A", description: "Fee"
    ))

    assert_equal [ matched ], BankTransaction.by_match("matched").to_a
    assert_equal [ open ], BankTransaction.by_match("unmatched").to_a
    assert_equal 2, BankTransaction.by_match(nil).count
  end

  test "by_date_range includes both end dates and may be open ended" do
    early = transaction("EARLY", occurred_on: Date.new(2025, 11, 1))
    middle = transaction("MIDDLE", occurred_on: Date.new(2025, 12, 1))
    late = transaction("LATE", occurred_on: Date.new(2025, 12, 31))

    assert_equal [ early, middle, late ].sort_by(&:id), BankTransaction.by_date_range(nil, nil).sort_by(&:id)
    assert_equal [ middle, late ].sort_by(&:id), BankTransaction.by_date_range(Date.new(2025, 12, 1), nil).sort_by(&:id)
    assert_equal [ early, middle ].sort_by(&:id), BankTransaction.by_date_range(nil, Date.new(2025, 12, 1)).sort_by(&:id)
    assert_equal [ late ], BankTransaction.by_date_range(Date.new(2025, 12, 31), Date.new(2025, 12, 31)).to_a
  end

  test "latest_date is the date of the most recent transaction" do
    assert_nil BankTransaction.latest_date
    transaction("A", occurred_on: Date.new(2025, 10, 1))
    transaction("B", occurred_on: Date.new(2025, 12, 30))

    assert_equal Date.new(2025, 12, 30), BankTransaction.latest_date
  end
end
