# Moderates new forum topics using LLM against ethics code
class ModerateForumTopicJob < ApplicationJob
  queue_as :default

  def perform(topic_id)
    topic = Thredded::Topic.find_by(id: topic_id)
    return unless topic

    # Only moderate topics that are pending moderation
    return unless topic.moderation_state == "pending_moderation"

    first_post = topic.posts.first
    return unless first_post

    result = ForumModerationService.new(
      content: first_post.content,
      title: topic.title
    ).check

    if result.approved?
      topic.moderation_state = "approved"
      topic.save!

      first_post.moderation_state = "approved"
      first_post.save!

      Rails.logger.info("Forum topic #{topic_id} auto-approved: #{result.reason}")
    else
      # Leave in pending state for human review
      Rails.logger.info("Forum topic #{topic_id} flagged for review: #{result.reason}")

      # Create a moderation record for visibility
      Thredded::PostModerationRecord.create!(
        post: first_post,
        messageboard: topic.messageboard,
        post_user: first_post.user,
        moderator: nil,
        moderation_state: "pending_moderation",
        previous_moderation_state: "pending_moderation",
        created_at: Time.current
      )
    end
  end
end
