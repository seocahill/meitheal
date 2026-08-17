require "test_helper"

class EmailGroupTest < ActiveSupport::TestCase
  test "valid email group with required attributes" do
    group = EmailGroup.new(
      name: "Test Group",
      local_part: "test-valid-group"
    )
    assert group.valid?, group.errors.full_messages.join(", ")
  end

  test "requires name" do
    group = EmailGroup.new(local_part: "test-noname")
    assert_not group.valid?
    assert_includes group.errors[:name], "can't be blank"
  end

  test "requires local_part" do
    group = EmailGroup.new(name: "All Members")
    assert_not group.valid?
    assert_includes group.errors[:local_part], "can't be blank"
  end

  test "local_part must be unique" do
    EmailGroup.create!(name: "Test", local_part: "unique-test-part")
    duplicate = EmailGroup.new(name: "Duplicate", local_part: "unique-test-part")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:local_part], "has already been taken"
  end

  test "local_part format validation" do
    group = EmailGroup.new(name: "Test", local_part: "Invalid Email!")
    assert_not group.valid?
    assert_includes group.errors[:local_part], "only allows lowercase letters, numbers, and hyphens"
  end

  test "valid local_part formats" do
    valid_parts = [ "test-format-1", "test-format-2", "test-format-3", "test-format-4" ]
    valid_parts.each do |part|
      group = EmailGroup.new(name: "Test", local_part: part)
      assert group.valid?, "Expected #{part} to be valid: #{group.errors.full_messages.join(", ")}"
    end
  end

  test "email_address returns full address" do
    group = EmailGroup.new(name: "Test", local_part: "test-email")
    assert_equal "test-email@thencf.art", group.email_address
  end

  test "active scope returns only active groups" do
    active = EmailGroup.create!(name: "Active", local_part: "scope-test-active", active: true)
    inactive = EmailGroup.create!(name: "Inactive", local_part: "scope-test-inactive", active: false)

    assert_includes EmailGroup.active, active
    assert_not_includes EmailGroup.active, inactive
  end

  test "can add members to group" do
    group = email_groups(:all_members)
    user = users(:viewer)

    # Clear existing memberships first
    group.members.delete_all
    group.members << user
    assert_includes group.members, user
    assert_includes user.email_groups, group
  end

  test "add_member creates membership for new user" do
    group = email_groups(:all_members)
    user = users(:viewer)
    group.email_group_memberships.delete_all

    group.add_member(user)

    assert_includes group.reload.members, user
  end

  test "add_member is idempotent when member already exists" do
    group = email_groups(:all_members)
    user = users(:viewer)
    group.email_group_memberships.delete_all
    group.email_group_memberships.create!(user: user)

    assert_nothing_raised { group.add_member(user) }
    assert_equal 1, group.email_group_memberships.where(user: user).count
  end
end
