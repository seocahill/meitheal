require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  setup do
    @user = users(:viewer)
  end

  test "valid profile with required attributes" do
    profile = Profile.new(user: @user, name: "Test Artist")
    assert profile.valid?
  end

  test "requires user" do
    profile = Profile.new(name: "Test")
    assert_not profile.valid?
    assert_includes profile.errors[:user], "must exist"
  end

  test "requires name" do
    profile = Profile.new(user: @user)
    assert_not profile.valid?
    assert_includes profile.errors[:name], "can't be blank"
  end

  test "user can only have one profile" do
    Profile.create!(user: @user, name: "First Profile")
    duplicate = Profile.new(user: @user, name: "Second Profile")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "skills_list returns array from comma-separated string" do
    profile = Profile.new(skills: "painting, sculpture, digital art")
    assert_equal ["painting", "sculpture", "digital art"], profile.skills_list
  end

  test "skills_list handles nil" do
    profile = Profile.new(skills: nil)
    assert_equal [], profile.skills_list
  end

  test "scope visible returns only visible profiles" do
    visible = Profile.create!(user: @user, name: "Visible", visible: true)
    hidden_user = User.create!(email_address: "hidden@test.com", password: "password")
    hidden = Profile.create!(user: hidden_user, name: "Hidden", visible: false)

    assert_includes Profile.visible, visible
    assert_not_includes Profile.visible, hidden
  end

  test "scope with_skill finds profiles by skill" do
    painter = Profile.create!(user: @user, name: "Painter", skills: "painting, drawing")
    sculptor_user = User.create!(email_address: "sculptor@test.com", password: "password")
    sculptor = Profile.create!(user: sculptor_user, name: "Sculptor", skills: "sculpture, ceramics")

    results = Profile.with_skill("painting")
    assert_includes results, painter
    assert_not_includes results, sculptor
  end

  test "scope search finds profiles by name or bio" do
    profile1 = Profile.create!(user: @user, name: "Alice Smith", bio: "Visual artist")
    profile2_user = User.create!(email_address: "bob@test.com", password: "password")
    profile2 = Profile.create!(user: profile2_user, name: "Bob Jones", bio: "Musician and painter")

    results = Profile.search("alice")
    assert_includes results, profile1
    assert_not_includes results, profile2

    results = Profile.search("painter")
    assert_includes results, profile2
    assert_not_includes results, profile1
  end
end
