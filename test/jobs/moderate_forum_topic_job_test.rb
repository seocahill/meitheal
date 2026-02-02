require "test_helper"

class ModerateForumTopicJobTest < ActiveSupport::TestCase
  setup do
    # Create a messageboard for testing
    @messageboard = Thredded::Messageboard.create!(
      name: "Test Board",
      slug: "test-board",
      description: "For testing"
    )

    @user = users(:viewer)

    # Ensure user has thredded user details
    Thredded::UserDetail.find_or_create_by!(user_id: @user.id)
  end

  test "does nothing if topic not found" do
    assert_nothing_raised do
      ModerateForumTopicJob.perform_now(999999)
    end
  end

  test "does nothing if topic is not pending moderation" do
    topic = Thredded::Topic.create!(
      messageboard: @messageboard,
      user: @user,
      title: "Approved Topic",
      moderation_state: "approved"
    )

    Thredded::Post.create!(
      postable: topic,
      messageboard: @messageboard,
      user: @user,
      content: "Some content"
    )

    # Should not change state
    ModerateForumTopicJob.perform_now(topic.id)

    topic.reload
    assert_equal "approved", topic.moderation_state
  end

  test "does nothing if topic has no posts" do
    topic = Thredded::Topic.create!(
      messageboard: @messageboard,
      user: @user,
      title: "Empty Topic",
      moderation_state: "pending_moderation"
    )

    # No posts created
    ModerateForumTopicJob.perform_now(topic.id)

    topic.reload
    # Still pending since no posts to moderate
    assert_equal "pending_moderation", topic.moderation_state
  end
end
