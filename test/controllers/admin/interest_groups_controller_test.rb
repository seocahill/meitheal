require "test_helper"

class Admin::InterestGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
  end

  test "owner and editor can see the groups" do
    [ @owner, @editor ].each do |user|
      sign_in_as(user)
      get admin_interest_groups_path
      assert_response :success
    end
  end

  test "viewer cannot see the groups" do
    sign_in_as(@viewer)
    get admin_interest_groups_path
    assert_redirected_to root_path
  end

  test "unauthenticated user cannot see the groups" do
    get admin_interest_groups_path
    assert_redirected_to new_session_path
  end

  test "each group links to its members with a count" do
    @owner.profile.update!(interests: "punk-music, events")
    @editor.profile.update!(interests: "music, events")
    sign_in_as(@owner)

    get admin_interest_groups_path
    assert_select "a[href='#{admin_users_path(interest: "events")}']", text: /2 members/
    assert_select "a[href='#{admin_users_path(interest: "music")}']", text: /1 member\b/
    assert_select "a[href='#{admin_users_path(interest: "punk-music")}']", text: /1 member\b/
  end

  test "a group previews the names of its members" do
    @editor.profile.update!(interests: "music")
    sign_in_as(@owner)

    get admin_interest_groups_path
    assert_select "a[href='#{admin_users_path(interest: "music")}']", text: /Editor User/
  end

  test "a long group shows a few names and how many more" do
    6.times do |i|
      user = User.create!(email_address: "member#{i}@example.com", password: "password")
      Profile.create!(user: user, name: "Member #{i}", interests: "music")
    end
    sign_in_as(@owner)

    get admin_interest_groups_path
    assert_select "a[href='#{admin_users_path(interest: "music")}']", text: /\+ 2 more/
  end

  test "largest groups come first" do
    @owner.profile.update!(interests: "events, music")
    @editor.profile.update!(interests: "music")
    sign_in_as(@owner)

    get admin_interest_groups_path
    hrefs = css_select("main a[href*='interest=']").map { |a| a["href"] }
    assert_equal [ admin_users_path(interest: "music"), admin_users_path(interest: "events") ], hrefs
  end

  test "says so when no interests are set" do
    sign_in_as(@owner)
    get admin_interest_groups_path
    assert_select "main", text: /No interests have been set yet/
  end

  test "the sidebar links to the groups" do
    sign_in_as(@editor)
    get admin_users_path
    assert_select "aside a[href='#{admin_interest_groups_path}']"
  end
end
