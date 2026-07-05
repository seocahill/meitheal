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

  test "destroying a user nullifies their posts" do
    user = User.create!(email_address: "nullify-posts@example.com", password: "password123")
    post = Post.create!(user: user, title: "Orphan Post", slug: "orphan-post", post_type: 0)

    assert_difference "Post.count", 0 do
      user.destroy!
    end

    assert_nil post.reload.user_id
  end

  test "destroying a user nullifies their proposals" do
    user = User.create!(email_address: "nullify-proposals@example.com", password: "password123")
    opportunity = funding_opportunities(:arts_council_grant)
    proposal = Proposal.create!(
      user: user,
      funding_opportunity: opportunity,
      title: "Orphan Proposal",
      status: :draft
    )

    assert_difference "Proposal.count", 0 do
      user.destroy!
    end

    assert_nil proposal.reload.user_id
  end
end
