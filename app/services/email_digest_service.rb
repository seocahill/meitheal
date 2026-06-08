class EmailDigestService
  def initialize(chat: nil)
    @chat = chat
  end

  def generate
    return nil unless llm_configured?

    emails = recent_emails
    return nil if emails.empty?

    summarize(emails)
  rescue => e
    Rails.logger.error("Email digest error: #{e.message}")
    nil
  end

  private

  def llm_configured?
    @chat.present? ||
      RubyLLM.config.mistral_api_key.present? ||
      RubyLLM.config.openai_api_key.present? ||
      RubyLLM.config.anthropic_api_key.present?
  end

  def recent_emails
    CachedEmail.visible.where("received_at >= ?", 24.hours.ago).order(received_at: :desc)
  end

  def summarize(emails)
    response = chat.ask(build_prompt(emails))
    response.content.presence
  end

  def chat
    @chat ||= RubyLLM.chat
  end

  def build_prompt(emails)
    email_list = emails.map.with_index(1) do |email, i|
      <<~EMAIL
        #{i}. From: #{email.from_address}
           Subject: #{email.subject}
           Summary: #{email.summary}
      EMAIL
    end.join("\n")

    <<~PROMPT
      You are an executive assistant summarizing the day's email for an admin of a community arts co-op.
      Review the following #{emails.size} emails received in the last 24 hours and produce a concise digest.

      Highlight:
      - Action items that need a response or decision
      - Urgent or time-sensitive matters
      - Important updates or requests

      Group related emails together if applicable. Keep it concise and scannable.

      EMAILS:
      #{email_list}
    PROMPT
  end
end
