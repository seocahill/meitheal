require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  test "valid payment with required attributes" do
    membership = memberships(:active_membership)
    payment = Payment.new(
      membership: membership,
      amount_cents: 2000,
      paid_on: Date.current,
      payment_method: :cash
    )
    assert payment.valid?
  end

  test "requires membership" do
    payment = Payment.new(amount_cents: 2000, paid_on: Date.current, payment_method: :cash)
    assert_not payment.valid?
    assert_includes payment.errors[:membership], "must exist"
  end

  test "requires amount_cents" do
    payment = Payment.new(
      membership: memberships(:active_membership),
      paid_on: Date.current,
      payment_method: :cash
    )
    assert_not payment.valid?
    assert_includes payment.errors[:amount_cents], "can't be blank"
  end

  test "amount_cents must be positive" do
    payment = Payment.new(
      membership: memberships(:active_membership),
      amount_cents: -100,
      paid_on: Date.current,
      payment_method: :cash
    )
    assert_not payment.valid?
    assert_includes payment.errors[:amount_cents], "must be greater than 0"
  end

  test "requires paid_on" do
    payment = Payment.new(
      membership: memberships(:active_membership),
      amount_cents: 2000,
      payment_method: :cash
    )
    assert_not payment.valid?
    assert_includes payment.errors[:paid_on], "can't be blank"
  end

  test "requires payment_method" do
    payment = Payment.new(
      membership: memberships(:active_membership),
      amount_cents: 2000,
      paid_on: Date.current
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
      payment_method: :cash
    )
    old = Payment.create!(
      membership: membership,
      amount_cents: 2000,
      paid_on: 2.months.ago,
      payment_method: :cash
    )

    assert_includes Payment.recent, recent
    assert_not_includes Payment.recent, old
  end
end
