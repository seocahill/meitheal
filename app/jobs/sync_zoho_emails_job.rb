class SyncZohoEmailsJob < ApplicationJob
  include Rails.application.routes.url_helpers

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
  rescue ZohoMailService::ApiError, Faraday::Error => e
    Rails.logger.error("SyncZohoEmailsJob network/API error: #{e.message}")
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
      subject: email_data["subject"].presence || "(no subject)",
      summary: email_data["summary"],
      body: body,
      received_at: Time.at(email_data["receivedTime"].to_i / 1000)
    )

    rewritten = resolve_inline_images(cached, folder_id, message_id, body)
    cached.update_column(:body, rewritten) if rewritten != body

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

  def resolve_inline_images(cached_email, folder_id, message_id, body)
    return body unless body&.include?("ImageDisplay")

    doc = Nokogiri::HTML::DocumentFragment.parse(body)
    changed = false

    doc.css("img[src*='ImageDisplay']").each do |img|
      params = Rack::Utils.parse_query(URI.parse(img["src"]).query)
      content_id = params["cid"]
      filename = params["f"] || "inline.jpg"

      next unless content_id.present?

      image_data = @zoho.download_inline_image(
        folder_id: folder_id,
        message_id: message_id,
        content_id: content_id
      )

      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(image_data),
        filename: filename,
        content_type: image_content_type(filename)
      )
      cached_email.attachments.attach(blob)

      img["src"] = rails_blob_path(blob, only_path: true)
      changed = true
    rescue ZohoMailService::ApiError => e
      Rails.logger.warn("SyncZohoEmailsJob: Could not download inline image #{content_id} for #{message_id}: #{e.message}")
    end

    changed ? doc.to_html : body
  end

  def image_content_type(filename)
    case File.extname(filename).downcase
    when ".jpg", ".jpeg" then "image/jpeg"
    when ".png"          then "image/png"
    when ".gif"          then "image/gif"
    when ".webp"         then "image/webp"
    else                      "image/jpeg"
    end
  end

  def fetch_body(folder_id, message_id)
    content = @zoho.email(folder_id: folder_id, message_id: message_id)
    content&.dig("content")
  rescue ZohoMailService::ApiError => e
    Rails.logger.warn("SyncZohoEmailsJob: Could not fetch body for #{message_id}: #{e.message}")
    nil
  end
end
