# Checks forum content against the NCF ethics code using LLM
class ForumModerationService
  ETHICS_CODE_SLUG = "ethics".freeze

  ModerationResult = Struct.new(:approved, :reason, keyword_init: true) do
    def approved?
      approved
    end
  end

  def initialize(content:, title: nil)
    @content = content
    @title = title
  end

  def check
    return ModerationResult.new(approved: true, reason: "LLM not configured") unless llm_configured?

    begin
      response = chat.ask(prompt)
      parse_response(response.content)
    rescue => e
      Rails.logger.error("Forum moderation error: #{e.message}")
      # On error, flag for human review
      ModerationResult.new(approved: false, reason: "Moderation check failed - flagged for review")
    end
  end

  private

  def llm_configured?
    RubyLLM.config.openai_api_key.present? || RubyLLM.config.anthropic_api_key.present?
  end

  def chat
    @chat ||= RubyLLM.chat(model: preferred_model)
  end

  def preferred_model
    if RubyLLM.config.anthropic_api_key.present?
      "claude-3-5-haiku-latest"
    else
      "gpt-4o-mini"
    end
  end

  def ethics_code
    @ethics_code ||= begin
      page = Page.find_by(slug: ETHICS_CODE_SLUG, visibility: :published)
      if page&.content.present?
        # Strip HTML tags for cleaner prompt
        ActionController::Base.helpers.strip_tags(page.content.to_s)
      else
        default_ethics_code
      end
    end
  end

  def default_ethics_code
    <<~CODE
      NCF Ethics Code:
      - We welcome all people regardless of background, identity, or experience level
      - We listen with openness and speak with kindness
      - We share knowledge and support fellow artists and makers
      - We act honestly and transparently
      - We do not tolerate content that promotes hatred or discrimination
      - We address conflicts constructively and in good faith
    CODE
  end

  def prompt
    <<~PROMPT
      You are a content moderator for a community arts co-op forum. Review the following forum post against our ethics code.

      ETHICS CODE:
      #{ethics_code}

      POST TO REVIEW:
      #{@title.present? ? "Title: #{@title}\n" : ""}Content: #{@content}

      Evaluate if this post violates any principles in our ethics code. Consider:
      - Does it contain hate speech, discrimination, or harassment?
      - Is it disrespectful or unkind to other members?
      - Does it promote harmful or unethical behavior?
      - Is it spam or off-topic promotional content?

      Respond with EXACTLY one of these formats:
      APPROVED - [brief reason why it's acceptable]
      REJECTED - [specific ethics code violation]

      Be permissive for genuine discussions, even if critical or debating. Only reject clear violations.
    PROMPT
  end

  def parse_response(response_text)
    text = response_text.to_s.strip

    if text.start_with?("APPROVED")
      reason = text.sub(/^APPROVED\s*-?\s*/, "").strip
      ModerationResult.new(approved: true, reason: reason.presence || "Content approved")
    elsif text.start_with?("REJECTED")
      reason = text.sub(/^REJECTED\s*-?\s*/, "").strip
      ModerationResult.new(approved: false, reason: reason.presence || "Content flagged for review")
    else
      # Ambiguous response - flag for human review
      ModerationResult.new(approved: false, reason: "Moderation result unclear - flagged for review")
    end
  end
end
