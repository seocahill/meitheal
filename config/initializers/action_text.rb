# Allow iframes in Action Text content (for YouTube embeds).
# allowed_tags may be nil if Lexxy's on_load hook hasn't fired yet (our hook can fire first).
# We fall back to the sanitizer class defaults so Lexxy inherits our addition when it runs.
ActiveSupport.on_load(:action_text_content) do
  helper = Class.new.include(ActionText::ContentHelper).new
  base_tags = ActionText::ContentHelper.allowed_tags || helper.sanitizer_allowed_tags
  base_attrs = ActionText::ContentHelper.allowed_attributes || helper.sanitizer_allowed_attributes
  ActionText::ContentHelper.allowed_tags = base_tags + %w[iframe]
  ActionText::ContentHelper.allowed_attributes = base_attrs + %w[allow allowfullscreen frameborder loading referrerpolicy]
end
