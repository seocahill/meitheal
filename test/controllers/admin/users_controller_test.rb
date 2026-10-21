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

  test "editor can access users index" do
    sign_in_as(@editor)
    get admin_users_path
    assert_response :success
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

  # Search
  test "index searches by email" do
    sign_in_as(@owner)
    get admin_users_path(q: "VIEWER@exam")
    assert_response :success
    assert_includes response.body, "viewer@example.com"
    refute_includes response.body, "editor@example.com"
  end

  test "index searches by profile name" do
    sign_in_as(@owner)
    get admin_users_path(q: "editor user")
    assert_response :success
    assert_includes response.body, "editor@example.com"
    refute_includes response.body, "viewer@example.com"
  end

  test "index search treats % and _ literally" do
    sign_in_as(@owner)
    get admin_users_path(q: "%")
    assert_response :success
    assert_select "tbody tr", text: /No users found/
  end

  test "index search combines with the pending tab" do
    User.create!(email_address: "pending-mary@example.com", password: "password", approved: false)
    User.create!(email_address: "pending-sean@example.com", password: "password", approved: false)
    sign_in_as(@owner)

    get admin_users_path(approved: "pending", q: "mary")
    assert_includes response.body, "pending-mary@example.com"
    refute_includes response.body, "pending-sean@example.com"
    refute_includes response.body, "viewer@example.com"
  end

  test "search form and tabs keep each other's filters" do
    sign_in_as(@owner)
    get admin_users_path(approved: "pending", q: "mary")
    assert_select "form[action='#{admin_users_path}'] input[name='q'][value='mary']"
    assert_select "form input[type='hidden'][name='approved'][value='pending']"
    assert_select "a[href*='q=mary']", text: /All Users/
  end

  # Interests
  test "index shows each member's interests" do
    @editor.profile.update!(interests: "music, film-tv")
    sign_in_as(@owner)
    get admin_users_path
    assert_select "tbody tr", text: /Editor User/ do
      assert_select "a[href='#{admin_users_path(interest: "film-tv")}']", text: "film-tv"
      assert_select "a[href='#{admin_users_path(interest: "music")}']", text: "music"
    end
  end

  test "index filters by whole interest" do
    @owner.profile.update!(interests: "punk-music")
    @editor.profile.update!(interests: "events, music")
    sign_in_as(@owner)

    get admin_users_path(interest: "music")
    assert_select "tbody tr", count: 1
    assert_select "tbody tr", text: /editor@example.com/
  end

  test "interest filter combines with search and the pending tab" do
    @owner.profile.update!(interests: "music")
    @editor.profile.update!(interests: "music")
    sign_in_as(@owner)

    get admin_users_path(interest: "music", q: "editor")
    assert_select "tbody tr", count: 1
    assert_select "tbody tr", text: /editor@example.com/
    assert_select "form input[type='hidden'][name='interest'][value='music']"
    assert_select "a[href*='interest=music']", text: /All Users/
  end

  test "index offers the interests in use as a filter" do
    @editor.profile.update!(interests: "music, events")
    sign_in_as(@owner)
    get admin_users_path
    assert_select "select[name='interest'] option", text: "events"
    assert_select "select[name='interest'] option", text: "music"
    assert_select "select[name='interest'] option", text: "theatre", count: 0
  end

  test "edit form has an interests field for members with a profile" do
    sign_in_as(@owner)
    get edit_admin_user_path(@viewer)
    assert_select "input[name='user[profile_attributes][interests]']", count: 0

    Profile.create!(user: @viewer, name: "Viewer", interests: "music")
    get edit_admin_user_path(@viewer)
    assert_select "input[name='user[profile_attributes][interests]'][value='music']"
  end

  test "editor can set a member's interests" do
    Profile.create!(user: @viewer, name: "Viewer")
    sign_in_as(@editor)

    patch admin_user_path(@viewer), params: { user: { profile_attributes: { interests: "music, theatre" } } }
    assert_redirected_to admin_users_path
    assert_equal "music, theatre", @viewer.profile.reload.interests
  end

  test "interests cannot rename the profile through the user form" do
    Profile.create!(user: @viewer, name: "Viewer")
    sign_in_as(@owner)

    patch admin_user_path(@viewer), params: { user: { profile_attributes: { name: "Renamed", interests: "music" } } }
    assert_equal "Viewer", @viewer.profile.reload.name
  end

  # Editor access
  test "editor sees users without owner-only controls" do
    User.create!(email_address: "pending@example.com", password: "password", approved: false)
    sign_in_as(@editor)
    get admin_users_path

    assert_select "a", text: "Add User", count: 0
    assert_select "button", text: "Delete", count: 0
    assert_select "button", text: "Approve", count: 1
    assert_select "a[href='#{edit_admin_user_path(@viewer)}']", text: "Edit"
    assert_select "a[href='#{edit_admin_user_path(@owner)}']", count: 0
    assert_select "a[href='#{edit_admin_user_path(@editor)}']", count: 0
  end

  test "owner sees every control" do
    sign_in_as(@owner)
    get admin_users_path
    assert_select "a", text: "Add User"
    assert_select "button", text: "Delete"
    assert_select "a[href='#{edit_admin_user_path(@editor)}']", text: "Edit"
  end

  test "editor can approve a pending user" do
    pending = User.create!(email_address: "pending@example.com", password: "password", approved: false)
    sign_in_as(@editor)

    assert_difference "Membership.count", 1 do
      post approve_admin_user_path(pending)
    end
    assert pending.reload.approved?
  end

  test "editor can edit a viewer's email, password and approval but the form has no role" do
    sign_in_as(@editor)
    get edit_admin_user_path(@viewer)
    assert_response :success
    assert_select "select[name='user[role]']", count: 0

    patch admin_user_path(@viewer), params: { user: { email_address: "renamed@example.com", password: "newpassword1", approved: "0" } }
    assert_redirected_to admin_users_path
    @viewer.reload
    assert_equal "renamed@example.com", @viewer.email_address
    assert @viewer.authenticate("newpassword1")
    assert_not @viewer.approved?
  end

  test "editor cannot change a role" do
    sign_in_as(@editor)
    patch admin_user_path(@viewer), params: { user: { role: "owner" } }
    assert @viewer.reload.viewer?
  end

  test "editor cannot edit owners or other editors" do
    sign_in_as(@editor)
    [ @owner, @editor ].each do |target|
      get edit_admin_user_path(target)
      assert_redirected_to root_path

      assert_no_changes -> { target.reload.password_digest } do
        patch admin_user_path(target), params: { user: { password: "takeover123" } }
      end
      assert_redirected_to root_path
    end
  end

  test "editor cannot add or delete users" do
    sign_in_as(@editor)
    get new_admin_user_path
    assert_redirected_to root_path

    assert_no_difference "User.count" do
      post admin_users_path, params: { user: { email_address: "new@example.com", password: "password123", role: "viewer" } }
      delete admin_user_path(@viewer)
    end
  end

  test "viewer cannot approve or edit users" do
    pending = User.create!(email_address: "pending@example.com", password: "password", approved: false)
    sign_in_as(@viewer)

    post approve_admin_user_path(pending)
    assert_redirected_to root_path
    assert_not pending.reload.approved?

    get edit_admin_user_path(@viewer)
    assert_redirected_to root_path
  end

  test "editors see the admin links they can use in the sidebar" do
    sign_in_as(@editor)
    get admin_users_path

    %w[users memberships payments bookings].each do |section|
      assert_select "nav a[href='/admin/#{section}']", text: /#{section}/i
    end
    assert_select "nav a[href='/admin/proposals']", count: 0
  end

  # Approval tests
  test "approve creates associate membership for user without one" do
    sign_in_as(@owner)
    unapproved = User.create!(email_address: "pending@example.com", password: "password", approved: false)

    assert_difference "Membership.count", 1 do
      post approve_admin_user_path(unapproved)
    end

    unapproved.reload
    assert unapproved.approved?
    membership = unapproved.memberships.first
    assert membership.associate?
    assert_equal Date.current, membership.starts_on
    assert_nil membership.expires_on
  end

  test "approve does not create duplicate membership if user already has one" do
    sign_in_as(@owner)
    # editor already has a membership (expired_membership fixture)
    @editor.update!(approved: false)

    assert_no_difference "Membership.count" do
      post approve_admin_user_path(@editor)
    end

    @editor.reload
    assert @editor.approved?
  end
end
