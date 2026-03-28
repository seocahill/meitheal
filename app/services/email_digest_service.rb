class EmailDigestService
  INBOX_FOLDER_NAME = "Inbox".freeze

  def initialize(zoho_service: ZohoMailService.new, chat: nil)
    @zoho = zoho_service
    @chat = chat
  end

  def generate
    return nil unless @zoho.configured?
    return nil unless llm_configured?

    inbox_id = find_inbox_folder_id
    return nil unless inbox_id

    recent = recent_emails(inbox_id)
    return nil if recent.empty?

    summarize(recent)
  rescue ZohoMailService::ApiError => e
    Rails.logger.error("Email digest Zoho error: #{e.message}")
    nil
  rescue => e
    Rails.logger.error("Email digest error: #{e.message}")
    nil
  end

  private

  def llm_configured?
    RubyLLM.config.mistral_api_key.present? ||
      RubyLLM.config.openai_api_key.present? ||
      RubyLLM.config.anthropic_api_key.present?
  end

  def find_inbox_folder_id
    folder = @zoho.folders.find { |f| f["folderName"] == INBOX_FOLDER_NAME }
    folder&.dig("folderId")
  end

  def recent_emails(folder_id)
    cutoff = 24.hours.ago
    emails = @zoho.emails(folder_id: folder_id, limit: 50)
    emails.select { |e| Time.at(e["receivedTime"].to_i / 1000) > cutoff }
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
        #{i}. From: #{email["fromAddress"]}
           Subject: #{email["subject"]}
           Summary: #{email["summary"]}
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
