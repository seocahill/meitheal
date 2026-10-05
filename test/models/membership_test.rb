require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "valid membership with required attributes" do
    user = users(:viewer)
    membership = Membership.new(
      user: user,
      membership_type: :associate,
      starts_on: Date.current
    )
    assert membership.valid?
  end

  test "requires user" do
    membership = Membership.new(membership_type: :associate, starts_on: Date.current)
    assert_not membership.valid?
    assert_includes membership.errors[:user], "must exist"
  end

  test "requires membership_type" do
    membership = Membership.new(user: users(:viewer), starts_on: Date.current)
    assert_not membership.valid?
    assert_includes membership.errors[:membership_type], "can't be blank"
  end

  test "requires starts_on" do
    membership = Membership.new(user: users(:viewer), membership_type: :associate)
    assert_not membership.valid?
    assert_includes membership.errors[:starts_on], "can't be blank"
  end

  test "membership types include associate, concession, full, and youth" do
    assert_includes Membership.membership_types.keys, "associate"
    assert_includes Membership.membership_types.keys, "concession"
    assert_includes Membership.membership_types.keys, "full"
    assert_includes Membership.membership_types.keys, "youth"
  end

  test "active scope returns only current memberships" do
    user = users(:viewer)
    active = Membership.create!(
      user: user,
      membership_type: :associate,
      starts_on: 1.month.ago,
      expires_on: 1.month.from_now
    )
    expired = Membership.create!(
      user: users(:editor),
      membership_type: :associate,
      starts_on: 3.months.ago,
      expires_on: 1.month.ago
    )

    assert_includes Membership.active, active
    assert_not_includes Membership.active, expired
  end

  test "expired? returns true for expired membership" do
    membership = Membership.new(
      user: users(:viewer),
      membership_type: :associate,
      starts_on: 3.months.ago,
      expires_on: 1.day.ago
    )
    assert membership.expired?
  end

  test "expired? returns false for current membership" do
    membership = Membership.new(
      user: users(:viewer),
      membership_type: :associate,
      starts_on: 1.month.ago,
      expires_on: 1.month.from_now
    )
    assert_not membership.expired?
  end

  test "expired? returns false when no expiry set" do
    membership = Membership.new(
      user: users(:viewer),
      membership_type: :associate,
      starts_on: 1.month.ago
    )
    assert_not membership.expired?
  end

  # Payment status
  def membership_with(type:, expires_on:, user: users(:viewer))
    Membership.create!(user: user, membership_type: type, starts_on: 1.year.ago.to_date, expires_on: expires_on)
  end

  test "associate memberships owe no fee" do
    membership = membership_with(type: :associate, expires_on: nil)
    assert_equal :no_fee, membership.payment_status
  end

  test "fee-paying membership with a future expiry is paid" do
    assert_equal :paid, membership_with(type: :full, expires_on: 3.months.from_now.to_date).payment_status
  end

  test "fee-paying membership past its expiry is lapsed" do
    assert_equal :lapsed, membership_with(type: :concession, expires_on: 1.day.ago.to_date).payment_status
  end

  test "fee-paying membership with no expiry has no payment recorded and is unpaid" do
    assert_equal :unpaid, membership_with(type: :full, expires_on: nil).payment_status
  end

  test "payment status scopes split fee-paying memberships and exclude associates" do
    paid = membership_with(type: :full, expires_on: 3.months.from_now.to_date)
    lapsed = membership_with(type: :youth, expires_on: 1.day.ago.to_date)
    unpaid = membership_with(type: :full, expires_on: nil)
    associate = membership_with(type: :associate, expires_on: nil)

    assert_includes Membership.paid, paid
    assert_includes Membership.lapsed, lapsed
    assert_includes Membership.unpaid, unpaid
    assert_includes Membership.no_fee, associate
    [ Membership.paid, Membership.lapsed, Membership.unpaid ].each { |scope| assert_not_includes scope, associate }
    assert_not_includes Membership.paid, lapsed
    assert_not_includes Membership.unpaid, paid
  end

  test "renewing_soon returns paid memberships expiring within 30 days" do
    soon = membership_with(type: :full, expires_on: 10.days.from_now.to_date)
    later = membership_with(type: :full, expires_on: 90.days.from_now.to_date)
    lapsed = membership_with(type: :full, expires_on: 1.day.ago.to_date)

    assert_includes Membership.renewing_soon, soon
    assert_not_includes Membership.renewing_soon, later
    assert_not_includes Membership.renewing_soon, lapsed
  end

  # Recording payment
  test "record_payment! extends a lapsed membership a year from today and logs the payment" do
    membership = membership_with(type: :full, expires_on: 1.month.ago.to_date)

    assert_difference "membership.payments.count", 1 do
      membership.record_payment!(payment_method: :cash)
    end

    assert_equal 1.year.from_now.to_date, membership.reload.expires_on
    assert_equal :paid, membership.payment_status
    payment = membership.payments.last
    assert payment.cash?
    assert payment.completed?
    assert payment.membership?
    assert_equal Membership::FEE_CENTS[:full], payment.amount_cents
    assert_equal membership.user.email_address, payment.user_email
  end

  test "record_payment! on an unpaid membership starts the year from today" do
    membership = membership_with(type: :concession, expires_on: nil)
    membership.record_payment!(payment_method: :bank_transfer)
    assert_equal 1.year.from_now.to_date, membership.reload.expires_on
    assert_equal Membership::FEE_CENTS[:concession], membership.payments.last.amount_cents
  end

  test "record_payment! refuses associate memberships" do
    membership = membership_with(type: :associate, expires_on: nil)
    assert_raises(ArgumentError) { membership.record_payment!(payment_method: :cash) }
  end

  test "mark_unpaid! clears the expiry without deleting payments" do
    membership = membership_with(type: :full, expires_on: 3.months.from_now.to_date)
    membership.record_payment!(payment_method: :cash)
    membership.mark_unpaid!
    assert_nil membership.reload.expires_on
    assert_equal :unpaid, membership.payment_status
    assert_equal 1, membership.payments.count
  end
end
