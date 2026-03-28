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
    folders = [@inbox_folder]
    @stub_zoho.define_singleton_method(:folders) { folders }

    zoho_emails = @zoho_emails
    @stub_zoho.define_singleton_method(:emails) { |folder_id:, limit:| zoho_emails }

    @stub_zoho.define_singleton_method(:email) do |folder_id:, message_id:|
      { "content" => "<p>Email body for #{message_id}</p>" }
    end
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
