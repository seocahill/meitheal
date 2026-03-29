class SyncZohoEmailsJob < ApplicationJob
  queue_as :default

  INBOX_FOLDER_NAME = "Inbox".freeze
  SYNC_LIMIT = 50

  def perform(zoho_service: ZohoMailService.new)
    @zoho = zoho_service
    return unless @zoho.configured?

    inbox_id = find_inbox_folder_id
    return unless inbox_id

    emails = @zoho.emails(folder_id: inbox_id, limit: SYNC_LIMIT)
    emails.each { |email_data| sync_email(inbox_id, email_data) }
  rescue ZohoMailService::ApiError => e
    Rails.logger.error("SyncZohoEmailsJob Zoho error: #{e.message}")
  end

  private

  def find_inbox_folder_id
    folder = @zoho.folders.find { |f| f["folderName"] == INBOX_FOLDER_NAME }
    folder&.dig("folderId")
  end

  def sync_email(folder_id, email_data)
    message_id = email_data["messageId"]
    return if CachedEmail.exists?(zoho_message_id: message_id)

    body = fetch_body(folder_id, message_id)

    cached = CachedEmail.create!(
      zoho_message_id: message_id,
      zoho_folder_id: folder_id,
      from_address: email_data["fromAddress"],
      subject: email_data["subject"],
      summary: email_data["summary"],
      body: body,
      received_at: Time.at(email_data["receivedTime"].to_i / 1000)
    )

    sync_attachments(cached, folder_id, message_id)
  end

  def sync_attachments(cached_email, folder_id, message_id)
    attachment_list = @zoho.attachments(folder_id: folder_id, message_id: message_id)
    attachment_list.each do |att|
      data = @zoho.download_attachment(
        folder_id: folder_id,
        message_id: message_id,
        attachment_id: att["attachmentId"]
      )
      cached_email.attachments.attach(
        io: StringIO.new(data[:content]),
        filename: data[:filename],
        content_type: data[:content_type]
      )
    rescue ZohoMailService::ApiError => e
      Rails.logger.warn("SyncZohoEmailsJob: Could not download attachment #{att['attachmentId']} for #{message_id}: #{e.message}")
    end
  rescue ZohoMailService::ApiError => e
    Rails.logger.warn("SyncZohoEmailsJob: Could not fetch attachments for #{message_id}: #{e.message}")
  end

  def fetch_body(folder_id, message_id)
    content = @zoho.email(folder_id: folder_id, message_id: message_id)
    content&.dig("content")
  rescue ZohoMailService::ApiError => e
    Rails.logger.warn("SyncZohoEmailsJob: Could not fetch body for #{message_id}: #{e.message}")
    nil
  end
end
