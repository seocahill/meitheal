require "test_helper"

class EmailDigestServiceTest < ActiveSupport::TestCase
  test "returns nil when LLM is not configured" do
    original_mistral = RubyLLM.config.mistral_api_key
    RubyLLM.configure { |c| c.mistral_api_key = nil }

    service = EmailDigestService.new
    assert_nil service.generate
  ensure
    RubyLLM.configure { |c| c.mistral_api_key = original_mistral }
  end

  test "returns nil when no recent emails" do
    service = EmailDigestService.new
    assert_nil service.generate
  end

  test "returns digest when recent emails exist" do
    create_cached_email(subject: "Grant deadline tomorrow", received_at: 2.hours.ago)

    fake_chat = stub_chat("Here is your email digest summary")
    service = EmailDigestService.new(chat: fake_chat)

    result = service.generate
    assert_equal "Here is your email digest summary", result
  end

  test "builds prompt with sender, subject, and summary for each email" do
    create_cached_email(
      from_address: "alice@example.com",
      subject: "Important matter",
      summary: "Please review this",
      received_at: 1.hour.ago
    )

    captured_prompt = nil
    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) { |prompt| captured_prompt = prompt; OpenStruct.new(content: "digest") }

    service = EmailDigestService.new(chat: fake_chat)
    service.generate

    assert_includes captured_prompt, "alice@example.com"
    assert_includes captured_prompt, "Important matter"
    assert_includes captured_prompt, "Please review this"
  end

  test "only includes emails from last 24 hours" do
    create_cached_email(subject: "Recent", received_at: 2.hours.ago)
    create_cached_email(zoho_message_id: "old_msg", subject: "Old", received_at: 48.hours.ago)

    captured_prompt = nil
    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) { |prompt| captured_prompt = prompt; OpenStruct.new(content: "digest") }

    service = EmailDigestService.new(chat: fake_chat)
    service.generate

    assert_includes captured_prompt, "Recent"
    assert_not_includes captured_prompt, "Old"
  end

  test "excludes archived emails" do
    create_cached_email(subject: "Active email", received_at: 1.hour.ago, status: :unread)
    create_cached_email(zoho_message_id: "archived_msg", subject: "Archived email", received_at: 1.hour.ago, status: :archived)

    captured_prompt = nil
    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) { |prompt| captured_prompt = prompt; OpenStruct.new(content: "digest") }

    service = EmailDigestService.new(chat: fake_chat)
    service.generate

    assert_includes captured_prompt, "Active email"
    assert_not_includes captured_prompt, "Archived email"
  end

  test "handles LLM errors gracefully" do
    create_cached_email(received_at: 1.hour.ago)

    failing_chat = Object.new
    failing_chat.define_singleton_method(:ask) { |_| raise StandardError, "LLM unavailable" }

    service = EmailDigestService.new(chat: failing_chat)
    assert_nil service.generate
  end

  private

  def create_cached_email(attrs = {})
    CachedEmail.create!({
      zoho_message_id: attrs.delete(:zoho_message_id) || "msg_#{SecureRandom.hex(4)}",
      zoho_folder_id: "folder_inbox",
      from_address: "sender@example.com",
      subject: "Test Email",
      summary: "Test summary",
      received_at: 1.hour.ago
    }.merge(attrs))
  end

  def stub_chat(response_text)
    chat = Object.new
    chat.define_singleton_method(:ask) { |_| OpenStruct.new(content: response_text) }
    chat
  end
end
