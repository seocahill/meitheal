require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
  end

  # Access control tests
  test "owner can access users index" do
    sign_in_as(@owner)
    get admin_users_path
    assert_response :success
  end

  test "editor cannot access users index" do
    sign_in_as(@editor)
    get admin_users_path
    assert_redirected_to root_path
  end

  test "viewer cannot access users index" do
    sign_in_as(@viewer)
    get admin_users_path
    assert_redirected_to root_path
  end

  test "unauthenticated user cannot access users" do
    get admin_users_path
    assert_redirected_to new_session_path
  end

  # CRUD tests
  test "owner can view new user form" do
    sign_in_as(@owner)
    get new_admin_user_path
    assert_response :success
  end

  test "owner can create user" do
    sign_in_as(@owner)
    assert_difference "User.count" do
      post admin_users_path, params: {
        user: {
          email_address: "newmember@example.com",
          password: "password123",
          role: "viewer"
        }
      }
    end
    assert_redirected_to admin_users_path
  end

  test "owner can view edit form" do
    sign_in_as(@owner)
    get edit_admin_user_path(@viewer)
    assert_response :success
  end

  test "owner can update user role" do
    sign_in_as(@owner)
    patch admin_user_path(@viewer), params: {
      user: { role: "editor" }
    }
    assert_redirected_to admin_users_path
    @viewer.reload
    assert @viewer.editor?
  end

  test "owner can delete user" do
    sign_in_as(@owner)
    user_to_delete = User.create!(email_address: "todelete@example.com", password: "password")
    assert_difference "User.count", -1 do
      delete admin_user_path(user_to_delete)
    end
    assert_redirected_to admin_users_path
  end

  test "owner cannot delete themselves" do
    sign_in_as(@owner)
    assert_no_difference "User.count" do
      delete admin_user_path(@owner)
    end
    assert_redirected_to admin_users_path
  end
end
