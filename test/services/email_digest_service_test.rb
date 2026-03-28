require "test_helper"

class EmailDigestServiceTest < ActiveSupport::TestCase
  test "returns nil when Zoho is not configured" do
    zoho = ZohoMailService.new
    zoho.define_singleton_method(:configured?) { false }

    service = EmailDigestService.new(zoho_service: zoho)
    assert_nil service.generate
  end

  test "returns nil when LLM is not configured" do
    original_mistral = RubyLLM.config.mistral_api_key
    RubyLLM.configure { |c| c.mistral_api_key = nil }

    zoho = stub_zoho(folders: inbox_folders, emails: [])
    service = EmailDigestService.new(zoho_service: zoho)
    assert_nil service.generate
  ensure
    RubyLLM.configure { |c| c.mistral_api_key = original_mistral }
  end

  test "returns nil when no recent emails in inbox" do
    zoho = stub_zoho(folders: inbox_folders, emails: [])
    service = EmailDigestService.new(zoho_service: zoho)
    assert_nil service.generate
  end

  test "returns digest when recent emails exist" do
    emails = [
      { "messageId" => "msg1", "fromAddress" => "alice@example.com", "subject" => "Grant deadline tomorrow", "summary" => "The arts council grant closes Friday", "receivedTime" => recent_timestamp },
      { "messageId" => "msg2", "fromAddress" => "bob@example.com", "subject" => "Studio booking query", "summary" => "Can I book the front room next week?", "receivedTime" => recent_timestamp }
    ]

    zoho = stub_zoho(folders: inbox_folders, emails: emails)
    fake_chat = stub_chat("Here is your email digest summary")
    service = EmailDigestService.new(zoho_service: zoho, chat: fake_chat)

    result = service.generate
    assert_equal "Here is your email digest summary", result
  end

  test "builds prompt with sender, subject, and summary for each email" do
    emails = [
      { "messageId" => "msg1", "fromAddress" => "alice@example.com", "subject" => "Important matter", "summary" => "Please review this", "receivedTime" => recent_timestamp }
    ]

    zoho = stub_zoho(folders: inbox_folders, emails: emails)
    captured_prompt = nil
    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) { |prompt| captured_prompt = prompt; OpenStruct.new(content: "digest") }

    service = EmailDigestService.new(zoho_service: zoho, chat: fake_chat)
    service.generate

    assert_includes captured_prompt, "alice@example.com"
    assert_includes captured_prompt, "Important matter"
    assert_includes captured_prompt, "Please review this"
  end

  test "filters out emails older than 24 hours" do
    emails = [
      { "messageId" => "msg1", "fromAddress" => "alice@example.com", "subject" => "Recent", "summary" => "New email", "receivedTime" => recent_timestamp },
      { "messageId" => "msg2", "fromAddress" => "bob@example.com", "subject" => "Old", "summary" => "Old email", "receivedTime" => old_timestamp }
    ]

    zoho = stub_zoho(folders: inbox_folders, emails: emails)
    captured_prompt = nil
    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) { |prompt| captured_prompt = prompt; OpenStruct.new(content: "digest") }

    service = EmailDigestService.new(zoho_service: zoho, chat: fake_chat)
    service.generate

    assert_includes captured_prompt, "Recent"
    assert_not_includes captured_prompt, "Old"
  end

  test "handles Zoho API errors gracefully" do
    zoho = Object.new
    zoho.define_singleton_method(:configured?) { true }
    zoho.define_singleton_method(:folders) { raise ZohoMailService::ApiError, "Connection failed" }

    service = EmailDigestService.new(zoho_service: zoho)
    assert_nil service.generate
  end

  test "handles LLM errors gracefully" do
    emails = [
      { "messageId" => "msg1", "fromAddress" => "alice@example.com", "subject" => "Test", "summary" => "Content", "receivedTime" => recent_timestamp }
    ]

    zoho = stub_zoho(folders: inbox_folders, emails: emails)
    failing_chat = Object.new
    failing_chat.define_singleton_method(:ask) { |_| raise StandardError, "LLM unavailable" }

    service = EmailDigestService.new(zoho_service: zoho, chat: failing_chat)
    assert_nil service.generate
  end

  test "finds inbox folder from folder list" do
    folders = [
      { "folderId" => "111", "folderName" => "Sent" },
      { "folderId" => "222", "folderName" => "Inbox" },
      { "folderId" => "333", "folderName" => "Drafts" }
    ]

    zoho = stub_zoho(folders: folders, emails: [])
    service = EmailDigestService.new(zoho_service: zoho)
    service.generate

    assert_equal "222", zoho.last_folder_id
  end

  test "returns nil when inbox folder not found" do
    folders = [
      { "folderId" => "111", "folderName" => "Sent" },
      { "folderId" => "333", "folderName" => "Drafts" }
    ]

    zoho = stub_zoho(folders: folders, emails: [])
    service = EmailDigestService.new(zoho_service: zoho)
    assert_nil service.generate
  end

  private

  def inbox_folders
    [{ "folderId" => "12345", "folderName" => "Inbox" }]
  end

  def recent_timestamp
    # Zoho returns epoch milliseconds
    (Time.current.to_i - 1.hour.to_i) * 1000
  end

  def old_timestamp
    (Time.current.to_i - 48.hours.to_i) * 1000
  end

  def stub_zoho(folders:, emails:)
    zoho = Object.new
    zoho.define_singleton_method(:configured?) { true }
    zoho.define_singleton_method(:folders) { folders }
    zoho.instance_variable_set(:@_emails, emails)
    zoho.define_singleton_method(:last_folder_id) { @_last_folder_id }
    zoho.define_singleton_method(:emails) do |folder_id:, limit: 50|
      @_last_folder_id = folder_id
      @_emails
    end
    zoho
  end

  def stub_chat(response_text)
    chat = Object.new
    chat.define_singleton_method(:ask) { |_| OpenStruct.new(content: response_text) }
    chat
  end
end
