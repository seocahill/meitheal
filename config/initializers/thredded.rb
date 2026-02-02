# frozen_string_literal: true

# Thredded configuration for NCF Forum

# ==> User Configuration
Thredded.user_class = "User"

# User name - we use a method that gets name from profile
Thredded.user_name_column = :name

# User display name method
Thredded.user_display_name_method = :name

# Link to user profiles
Thredded.user_path = ->(user) {
  if user.profile.present?
    main_app.profile_path(user.profile)
  else
    nil
  end
}

# Current user method - we define this in ApplicationController
Thredded.current_user_method = :current_user

# User avatar using Gravatar
Thredded.avatar_url = ->(user) { RailsGravatar.src(user.email, 156, "mm") }

# ==> Permissions Configuration
# Admin and moderator are determined by our admin method on User
Thredded.moderator_column = :admin
Thredded.admin_column = :admin

# Content pending moderation should be hidden until approved
Thredded.content_visible_while_pending_moderation = false

# ==> UI configuration
Thredded.messageboards_order = :position
Thredded.show_messageboard_delete_button = true
Thredded.show_messageboard_group_page = true
Thredded.show_topic_followers = true
Thredded.currently_online_enabled = true
Thredded.private_messaging_enabled = true

# Use our application layout with Thredded content area
Thredded.layout = "thredded/application"

# ==> Email Configuration
Thredded.email_from = "forum@thencf.art"
Thredded.email_outgoing_prefix = "[NCF Forum] "

# ==> Error Handling - redirect to sign in on login required
Rails.application.config.to_prepare do
  Thredded::ApplicationController.module_eval do
    rescue_from Thredded::Errors::LoginRequired do |_exception|
      flash[:alert] = "Please sign in to access the forum."
      redirect_to main_app.new_session_path
    end
  end

  # ==> LLM Moderation for new topics
  # New topics from non-admin users start in pending_moderation state
  # and are checked against our ethics code by an LLM
  Thredded::Topic.class_eval do
    after_create :queue_ethics_moderation

    private

    def queue_ethics_moderation
      # Admins and editors bypass moderation
      return if user&.can_edit?

      # Set to pending moderation
      update_column(:moderation_state, "pending_moderation")

      # Queue LLM check
      ModerateForumTopicJob.perform_later(id)
    end
  end

  # Also moderate the first post
  Thredded::Post.class_eval do
    after_create :sync_moderation_state_with_topic

    private

    def sync_moderation_state_with_topic
      # If this is the first post in a topic, sync moderation state
      return unless postable.is_a?(Thredded::Topic)
      return if postable.posts.count > 1

      if postable.moderation_state == "pending_moderation"
        update_column(:moderation_state, "pending_moderation")
      end
    end
  end
end
