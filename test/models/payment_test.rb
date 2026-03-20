require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  test "valid payment with required attributes" do
    membership = memberships(:active_membership)
    payment = Payment.new(
      membership: membership,
      amount_cents: 2000,
      paid_on: Date.current,
      payment_method: :cash,
      user_email: "test@example.com",
      user_name: "Test User",
      description: "Test payment"
    )
    assert payment.valid?
  end

  test "requires membership" do
    payment = Payment.new(
      amount_cents: 2000,
      paid_on: Date.current,
      payment_method: :cash,
      user_email: "test@example.com",
      user_name: "Test User",
      description: "Test payment"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:membership], "must exist"
  end

  test "requires amount_cents" do
    payment = Payment.new(
      membership: memberships(:active_membership),
      paid_on: Date.current,
      payment_method: :cash,
      user_email: "test@example.com",
      user_name: "Test User",
      description: "Test payment"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:amount_cents], "can't be blank"
  end

  test "amount_cents must be positive" do
    payment = Payment.new(
      membership: memberships(:active_membership),
      amount_cents: -100,
      paid_on: Date.current,
      payment_method: :cash,
      user_email: "test@example.com",
      user_name: "Test User",
      description: "Test payment"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:amount_cents], "must be greater than 0"
  end

  test "requires paid_on" do
    payment = Payment.new(
      membership: memberships(:active_membership),
      amount_cents: 2000,
      payment_method: :cash,
      user_email: "test@example.com",
      user_name: "Test User",
      description: "Test payment"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:paid_on], "can't be blank"
  end

  test "requires payment_method" do
    payment = Payment.new(
      membership: memberships(:active_membership),
      amount_cents: 2000,
      paid_on: Date.current,
      user_email: "test@example.com",
      user_name: "Test User",
      description: "Test payment"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:payment_method], "can't be blank"
  end

  test "payment methods include cash transfer and other" do
    assert_includes Payment.payment_methods.keys, "cash"
    assert_includes Payment.payment_methods.keys, "bank_transfer"
    assert_includes Payment.payment_methods.keys, "other"
  end

  test "amount_euro returns amount in euros" do
    payment = Payment.new(amount_cents: 2050)
    assert_equal 20.50, payment.amount_euro
  end

  test "recent scope returns payments in last 30 days" do
    membership = memberships(:active_membership)
    recent = Payment.create!(
      membership: membership,
      amount_cents: 2000,
      paid_on: 1.week.ago,
      payment_method: :cash,
      user_email: "recent@example.com",
      user_name: "Recent User",
      description: "Recent payment"
    )
    old = Payment.create!(
      membership: membership,
      amount_cents: 2000,
      paid_on: 2.months.ago,
      payment_method: :cash,
      user_email: "old@example.com",
      user_name: "Old User",
      description: "Old payment"
    )

    assert_includes Payment.recent, recent
    assert_not_includes Payment.recent, old
  end

  test "requires user_email" do
    payment = Payment.new(
      membership: memberships(:active_membership),
      amount_cents: 2000,
      paid_on: Date.current,
      payment_method: :cash,
      user_name: "Test User",
      description: "Test payment"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:user_email], "can't be blank"
  end

  test "requires user_name" do
    payment = Payment.new(
      membership: memberships(:active_membership),
      amount_cents: 2000,
      paid_on: Date.current,
      payment_method: :cash,
      user_email: "test@example.com",
      description: "Test payment"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:user_name], "can't be blank"
  end

  test "requires description" do
    payment = Payment.new(
      membership: memberships(:active_membership),
      amount_cents: 2000,
      paid_on: Date.current,
      payment_method: :cash,
      user_email: "test@example.com",
      user_name: "Test User"
    )
    assert_not payment.valid?
    assert_includes payment.errors[:description], "can't be blank"
  end

  test "by_payment_method scope filters by payment method" do
    membership = memberships(:active_membership)
    cash_payment = Payment.create!(
      membership: membership,
      amount_cents: 2000,
      paid_on: Date.current,
      payment_method: :cash,
      user_email: "cash@example.com",
      user_name: "Cash User",
      description: "Cash payment"
    )
    sumup_payment = Payment.create!(
      membership: membership,
      amount_cents: 3000,
      paid_on: Date.current,
      payment_method: :sumup,
      user_email: "sumup@example.com",
      user_name: "SumUp User",
      description: "SumUp payment"
    )

    assert_includes Payment.by_payment_method("cash"), cash_payment
    assert_not_includes Payment.by_payment_method("cash"), sumup_payment
    assert_includes Payment.by_payment_method("sumup"), sumup_payment
    assert_not_includes Payment.by_payment_method("sumup"), cash_payment
  end

  test "by_date_range scope filters by date range" do
    membership = memberships(:active_membership)
    old_payment = Payment.create!(
      membership: membership,
      amount_cents: 2000,
      paid_on: 2.months.ago,
      payment_method: :cash,
      user_email: "old@example.com",
      user_name: "Old User",
      description: "Old payment"
    )
    recent_payment = Payment.create!(
      membership: membership,
      amount_cents: 3000,
      paid_on: 1.week.ago,
      payment_method: :cash,
      user_email: "recent@example.com",
      user_name: "Recent User",
      description: "Recent payment"
    )

    result = Payment.by_date_range(2.weeks.ago.to_date, Date.current)
    assert_includes result, recent_payment
    assert_not_includes result, old_payment
  end

  test "search scope finds payments by user email" do
    membership = memberships(:active_membership)
    payment = Payment.create!(
      membership: membership,
      amount_cents: 2000,
      paid_on: Date.current,
      payment_method: :cash,
      user_email: "unique@example.com",
      user_name: "Test User",
      description: "Test payment"
    )

    assert_includes Payment.search("unique@example"), payment
    assert_not_includes Payment.search("nonexistent@example"), payment
  end

  test "search scope finds payments by user name" do
    membership = memberships(:active_membership)
    payment = Payment.create!(
      membership: membership,
      amount_cents: 2000,
      paid_on: Date.current,
      payment_method: :cash,
      user_email: "test@example.com",
      user_name: "UniqueTestUser",
      description: "Test payment"
    )

    assert_includes Payment.search("UniqueTestUser"), payment
    assert_not_includes Payment.search("NonexistentUser"), payment
  end

  test "search scope finds payments by description" do
    membership = memberships(:active_membership)
    payment = Payment.create!(
      membership: membership,
      amount_cents: 2000,
      paid_on: Date.current,
      payment_method: :cash,
      user_email: "test@example.com",
      user_name: "Test User",
      description: "UniqueDescription for space hire"
    )

    assert_includes Payment.search("UniqueDescription"), payment
    assert_not_includes Payment.search("NonexistentDescription"), payment
  end
end
