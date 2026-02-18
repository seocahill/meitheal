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
end
