require "test_helper"

class SyncZohoEmailsJobTest < ActiveJob::TestCase
  setup do
    @stub_zoho = Object.new

    @inbox_folder = { "folderId" => "folder_inbox", "folderName" => "Inbox" }

    @zoho_emails = [
      {
        "messageId" => "msg_001",
        "fromAddress" => "alice@example.com",
        "subject" => "Art Exhibition Update",
        "summary" => "Details about the upcoming exhibition",
        "receivedTime" => (2.hours.ago.to_f * 1000).to_i.to_s
      },
      {
        "messageId" => "msg_002",
        "fromAddress" => "bob@example.com",
        "subject" => "Funding Application",
        "summary" => "New funding opportunity available",
        "receivedTime" => (1.hour.ago.to_f * 1000).to_i.to_s
      }
    ]

    @stub_zoho.define_singleton_method(:configured?) { true }
    folders = [ @inbox_folder ]
    @stub_zoho.define_singleton_method(:folders) { folders }

    zoho_emails = @zoho_emails
    @stub_zoho.define_singleton_method(:emails) { |folder_id:, limit:| zoho_emails }

    @stub_zoho.define_singleton_method(:email) do |folder_id:, message_id:|
      { "content" => "<p>Email body for #{message_id}</p>" }
    end

    @stub_zoho.define_singleton_method(:attachments) { |folder_id:, message_id:| [] }
    @stub_zoho.define_singleton_method(:download_attachment) { |folder_id:, message_id:, attachment_id:| raise "Should not be called" }
    @stub_zoho.define_singleton_method(:download_inline_image) { |folder_id:, message_id:, content_id:| raise "Should not be called" }
  end

  test "creates cached emails from Zoho inbox" do
    assert_difference "CachedEmail.count", 2 do
      SyncZohoEmailsJob.perform_now(zoho_service: @stub_zoho)
    end

    email = CachedEmail.find_by(zoho_message_id: "msg_001")
    assert_equal "folder_inbox", email.zoho_folder_id
    assert_equal "alice@example.com", email.from_address
    assert_equal "Art Exhibition Update", email.subject
    assert_equal "Details about the upcoming exhibition", email.summary
    assert_equal "<p>Email body for msg_001</p>", email.body
    assert email.unread?
  end

  test "skips emails that already exist" do
    CachedEmail.create!(
      zoho_message_id: "msg_001",
      zoho_folder_id: "folder_inbox",
      from_address: "alice@example.com",
      subject: "Art Exhibition Update",
      summary: "Old summary",
      body: "<p>Old body</p>",
      received_at: 2.hours.ago
    )

    assert_difference "CachedEmail.count", 1 do
      SyncZohoEmailsJob.perform_now(zoho_service: @stub_zoho)
    end

    # Existing email should not be overwritten
    email = CachedEmail.find_by(zoho_message_id: "msg_001")
    assert_equal "Old summary", email.summary
  end

  test "does nothing when Zoho is not configured" do
    @stub_zoho.define_singleton_method(:configured?) { false }

    assert_no_difference "CachedEmail.count" do
      SyncZohoEmailsJob.perform_now(zoho_service: @stub_zoho)
    end
  end

  test "does nothing when inbox folder not found" do
    @stub_zoho.define_singleton_method(:folders) { [] }

    assert_no_difference "CachedEmail.count" do
      SyncZohoEmailsJob.perform_now(zoho_service: @stub_zoho)
    end
  end

  test "handles Zoho API errors gracefully" do
    @stub_zoho.define_singleton_method(:folders) { raise ZohoMailService::ApiError, "Rate limited" }

    assert_nothing_raised do
      SyncZohoEmailsJob.perform_now(zoho_service: @stub_zoho)
    end
  end

  test "handles network connection failures gracefully" do
    @stub_zoho.define_singleton_method(:folders) { raise Faraday::ConnectionFailed.new("Connection reset by peer - SSL_connect") }

    assert_nothing_raised do
      SyncZohoEmailsJob.perform_now(zoho_service: @stub_zoho)
    end
  end

  test "downloads and attaches email attachments" do
    attachment_info = [
      { "attachmentId" => "att_001", "attachmentName" => "poster.jpg", "attachmentSize" => 1234, "contentType" => "image/jpeg" },
      { "attachmentId" => "att_002", "attachmentName" => "proposal.pdf", "attachmentSize" => 5678, "contentType" => "application/pdf" }
    ]

    @stub_zoho.define_singleton_method(:attachments) do |folder_id:, message_id:|
      message_id == "msg_001" ? attachment_info : []
    end

    @stub_zoho.define_singleton_method(:download_attachment) do |folder_id:, message_id:, attachment_id:|
      {
        content: "binary content for #{attachment_id}",
        filename: attachment_info.find { |a| a["attachmentId"] == attachment_id }["attachmentName"],
        content_type: attachment_info.find { |a| a["attachmentId"] == attachment_id }["contentType"]
      }
    end

    SyncZohoEmailsJob.perform_now(zoho_service: @stub_zoho)

    email = CachedEmail.find_by(zoho_message_id: "msg_001")
    assert_equal 2, email.attachments.count
    assert_equal "poster.jpg", email.attachments.first.filename.to_s

    email2 = CachedEmail.find_by(zoho_message_id: "msg_002")
    assert_equal 0, email2.attachments.count
  end

  test "continues syncing when attachment download fails" do
    @stub_zoho.define_singleton_method(:attachments) do |folder_id:, message_id:|
      [ { "attachmentId" => "att_001", "attachmentName" => "file.pdf", "attachmentSize" => 100, "contentType" => "application/pdf" } ]
    end

    @stub_zoho.define_singleton_method(:download_attachment) do |folder_id:, message_id:, attachment_id:|
      raise ZohoMailService::ApiError, "Download failed"
    end

    assert_difference "CachedEmail.count", 2 do
      SyncZohoEmailsJob.perform_now(zoho_service: @stub_zoho)
    end

    # Emails created but no attachments
    email = CachedEmail.find_by(zoho_message_id: "msg_001")
    assert_equal 0, email.attachments.count
  end

  test "downloads inline images and rewrites body URLs" do
    inline_src = "/mail/ImageDisplay?na=123&nmsgId=msg_001&f=poster.jpg&mode=inline&cid=ii_abc123&"
    @stub_zoho.define_singleton_method(:email) do |folder_id:, message_id:|
      { "content" => "<p>Hello</p><img src=\"#{inline_src}\"><p>Bye</p>" }
    end

    downloaded_cids = []
    @stub_zoho.define_singleton_method(:download_inline_image) do |folder_id:, message_id:, content_id:|
      downloaded_cids << content_id
      "fake-png-bytes"
    end

    SyncZohoEmailsJob.perform_now(zoho_service: @stub_zoho)

    assert_includes downloaded_cids, "ii_abc123"

    email = CachedEmail.find_by(zoho_message_id: "msg_001")
    # Body should not contain Zoho's ImageDisplay URL any more
    assert_no_match "ImageDisplay", email.body
    # Body should contain a rails blob path instead
    assert_match "/rails/active_storage", email.body
    # Surrounding content preserved
    assert_match "<p>Hello</p>", email.body
  end

  test "continues syncing when inline image download fails" do
    inline_src = "/mail/ImageDisplay?na=123&nmsgId=msg_001&f=img.png&mode=inline&cid=ii_bad&"
    @stub_zoho.define_singleton_method(:email) do |folder_id:, message_id:|
      { "content" => "<p>Text</p><img src=\"#{inline_src}\">" }
    end

    @stub_zoho.define_singleton_method(:download_inline_image) do |folder_id:, message_id:, content_id:|
      raise ZohoMailService::ApiError, "Not found"
    end

    assert_difference "CachedEmail.count", 2 do
      assert_nothing_raised { SyncZohoEmailsJob.perform_now(zoho_service: @stub_zoho) }
    end

    # Body left unchanged — displayable_body strips the broken tag at render time
    email = CachedEmail.find_by(zoho_message_id: "msg_001")
    assert_match "ImageDisplay", email.body
  end

  test "syncs email with blank subject using (No Subject) fallback" do
    @zoho_emails[0]["subject"] = ""
    @zoho_emails[1]["subject"] = nil

    assert_difference "CachedEmail.count", 2 do
      SyncZohoEmailsJob.perform_now(zoho_service: @stub_zoho)
    end

    assert_equal "(No Subject)", CachedEmail.find_by(zoho_message_id: "msg_001").subject
    assert_equal "(No Subject)", CachedEmail.find_by(zoho_message_id: "msg_002").subject
  end

  test "continues syncing when individual email content fetch fails" do
    call_count = 0
    @stub_zoho.define_singleton_method(:email) do |folder_id:, message_id:|
      call_count += 1
      raise ZohoMailService::ApiError, "Not found" if message_id == "msg_001"
      { "content" => "<p>Email body for #{message_id}</p>" }
    end

    assert_difference "CachedEmail.count", 2 do
      SyncZohoEmailsJob.perform_now(zoho_service: @stub_zoho)
    end

    # First email should be created without body
    email1 = CachedEmail.find_by(zoho_message_id: "msg_001")
    assert_nil email1.body

    # Second email should have body
    email2 = CachedEmail.find_by(zoho_message_id: "msg_002")
    assert_equal "<p>Email body for msg_002</p>", email2.body
  end
end
