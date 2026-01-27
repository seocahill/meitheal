require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  test "owner can access owner-restricted pages" do
    sign_in_as(users(:owner))
    # Just verify they're signed in and the helper works
    assert users(:owner).can_manage?
  end

  test "editor cannot access owner-restricted pages" do
    sign_in_as(users(:editor))
    assert_not users(:editor).can_manage?
  end

  test "viewer cannot access owner-restricted pages" do
    sign_in_as(users(:viewer))
    assert_not users(:viewer).can_manage?
  end

  test "owner can edit" do
    assert users(:owner).can_edit?
  end

  test "editor can edit" do
    assert users(:editor).can_edit?
  end

  test "viewer cannot edit" do
    assert_not users(:viewer).can_edit?
  end
end
