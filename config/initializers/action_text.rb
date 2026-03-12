# Allow iframes and video in Action Text content
# Action Text has its own sanitizer separate from config.action_view.sanitized_allowed_tags
Rails.application.config.after_initialize do
  ActionText::ContentHelper.allowed_tags = ActionText::ContentHelper.sanitizer.class.allowed_tags + [ "iframe", "video" ]
  ActionText::ContentHelper.allowed_attributes = ActionText::ContentHelper.sanitizer.class.allowed_attributes + [ "allow", "allowfullscreen", "frameborder", "loading", "referrerpolicy" ]
end
