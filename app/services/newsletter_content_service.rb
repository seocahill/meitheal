class NewsletterContentService
  def initialize(chat: nil)
    @chat = chat
  end

  def generate_news
    return nil if @chat.nil? && !llm_configured?

    emails = recent_emails
    return nil if emails.empty?

    response = chat.ask(build_prompt(emails))
    strip_code_fences(response.content.presence)
  rescue => e
    Rails.logger.error("NewsletterContentService error: #{e.message}")
    nil
  end

  private

  def llm_configured?
    RubyLLM.config.mistral_api_key.present? ||
      RubyLLM.config.openai_api_key.present? ||
      RubyLLM.config.anthropic_api_key.present?
  end

  def recent_emails
    CachedEmail.visible.where("received_at >= ?", 30.days.ago).order(received_at: :desc).limit(25)
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
      You are writing the "News" section of a newsletter for NCF (the North Connacht Co-op), a community arts co-op in Ballina, Co. Mayo, Ireland.

      Based on the following recent emails, write a concise news section for the newsletter.

      Requirements:
      - Write in a warm, community-focused tone
      - Group related items together
      - Focus on news relevant to members: exhibitions, workshops, collaborations, community events
      - Skip routine admin emails, spam, or irrelevant items
      - Format as HTML: use <h2> for the section header, <h3> for sub-items, <p> for paragraphs
      - Keep it scannable and concise
      - If no emails contain newsletter-worthy news, return a brief placeholder noting no major news this period

      RECENT EMAILS:
      #{email_list}

      Provide ONLY the HTML content. No explanatory text or code fences.
    PROMPT
  end

  def strip_code_fences(text)
    return nil unless text
    text.gsub(/\A```(?:html|markdown)?\n?/, "").gsub(/\n?```\z/, "")
  end
end
