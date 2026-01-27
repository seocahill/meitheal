require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @owner_profile = profiles(:owner_profile)
  end

  # Public directory
  test "index shows visible profiles to public" do
    get profiles_path
    assert_response :success
    assert_includes response.body, @owner_profile.name
  end

  test "index can filter by skill" do
    get profiles_path(skill: "administration")
    assert_response :success
    assert_includes response.body, @owner_profile.name
  end

  test "index can search by name" do
    get profiles_path(q: "Admin")
    assert_response :success
    assert_includes response.body, @owner_profile.name
  end

  test "show displays profile to public" do
    get profile_path(@owner_profile)
    assert_response :success
    assert_includes response.body, @owner_profile.name
  end

  test "show redirects for hidden profile" do
    @owner_profile.update!(visible: false)
    get profile_path(@owner_profile)
    assert_redirected_to profiles_path
  end

  # My profile management
  test "my_profile redirects to login when not authenticated" do
    get my_profile_path
    assert_redirected_to new_session_path
  end

  test "my_profile shows form to create profile if none exists" do
    sign_in_as(@viewer)
    get my_profile_path
    assert_response :success
    assert_includes response.body, "Create Your Profile"
  end

  test "my_profile shows edit form if profile exists" do
    sign_in_as(@owner)
    get my_profile_path
    assert_response :success
    assert_includes response.body, "Edit Your Profile"
  end

  test "user can create their profile" do
    sign_in_as(@viewer)
    assert_difference "Profile.count" do
      post my_profile_path, params: {
        profile: {
          name: "New Artist",
          bio: "I create art",
          skills: "painting, sculpture"
        }
      }
    end
    assert_redirected_to profile_path(Profile.last)
  end

  test "user can update their profile" do
    sign_in_as(@owner)
    patch my_profile_path, params: {
      profile: { name: "Updated Name" }
    }
    assert_redirected_to profile_path(@owner_profile)
    @owner_profile.reload
    assert_equal "Updated Name", @owner_profile.name
  end
end
