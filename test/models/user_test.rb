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

  test "can_manage? returns true only for owners" do
    owner = User.new(role: :owner)
    editor = User.new(role: :editor)
    viewer = User.new(role: :viewer)

    assert owner.can_manage?
    assert_not editor.can_manage?
    assert_not viewer.can_manage?
  end
end
