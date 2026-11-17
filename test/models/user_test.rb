require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "defaults to viewer role" do
    user = User.new(email_address: "test@example.com", password: "password123")
    assert user.viewer?
  end

  test "can be assigned owner role" do
    user = User.new(email_address: "owner@example.com", password: "password123", role: :owner)
    assert user.owner?
    assert_not user.editor?
    assert_not user.viewer?
  end

  test "can be assigned editor role" do
    user = User.new(email_address: "editor@example.com", password: "password123", role: :editor)
    assert user.editor?
  end

  test "owner? returns true only for owners" do
    owner = User.new(role: :owner)
    editor = User.new(role: :editor)
    viewer = User.new(role: :viewer)

    assert owner.owner?
    assert_not editor.owner?
    assert_not viewer.owner?
  end

  test "can_edit? returns true for owners and editors" do
    owner = User.new(role: :owner)
    editor = User.new(role: :editor)
    viewer = User.new(role: :viewer)

    assert owner.can_edit?
    assert editor.can_edit?
    assert_not viewer.can_edit?
  end

  test "requires unique email_address" do
    User.create!(email_address: "taken@example.com", password: "password123")
    duplicate = User.new(email_address: "taken@example.com", password: "password456")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  test "can_manage? returns true only for owners" do
    owner = User.new(role: :owner)
    editor = User.new(role: :editor)
    viewer = User.new(role: :viewer)

    assert owner.can_manage?
    assert_not editor.can_manage?
    assert_not viewer.can_manage?
  end

  test "booking_membership_problem is nil when the annual membership is paid" do
    assert_nil users(:viewer).booking_membership_problem
  end

  test "booking_membership_problem says a lapsed membership expired and when" do
    expired = memberships(:expired_membership)
    message = users(:editor).booking_membership_problem

    assert_includes message, "can't book a space"
    assert_includes message, "expired on #{expired.expires_on.strftime('%-d %B %Y')}"
  end

  test "booking_membership_problem says an associate has not paid the annual membership" do
    user = User.create!(email_address: "assoc@example.com", password: "password123", approved: true)
    user.memberships.create!(membership_type: :associate, starts_on: Date.current)

    assert_includes user.booking_membership_problem, "can't book a space"
    assert_includes user.booking_membership_problem, "paid annual membership"
  end

  test "booking_membership_problem says the same when there is no membership" do
    user = User.create!(email_address: "nomember@example.com", password: "password123", approved: true)

    assert_includes user.booking_membership_problem, "paid annual membership"
  end
end
