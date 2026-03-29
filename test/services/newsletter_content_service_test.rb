require "test_helper"

class NewsletterContentServiceTest < ActiveSupport::TestCase
  test "generates news section from cached emails" do
    create_cached_email(
      from_address: "gallery@example.com",
      subject: "New Exhibition Opening",
      summary: "A new contemporary art exhibition opens next week",
      received_at: 2.hours.ago
    )

    captured_prompt = nil
    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) do |prompt|
      captured_prompt = prompt
      OpenStruct.new(content: "<h2>News</h2><p>A new exhibition is coming...</p>")
    end

    service = NewsletterContentService.new(chat: fake_chat)
    result = service.generate_news

    assert_includes captured_prompt, "New Exhibition Opening"
    assert_includes captured_prompt, "gallery@example.com"
    assert_includes result, "new exhibition"
  end

  test "returns nil when no recent emails" do
    service = NewsletterContentService.new
    assert_nil service.generate_news
  end

  test "returns nil when LLM is not configured" do
    create_cached_email(received_at: 1.hour.ago)

    original_mistral = RubyLLM.config.mistral_api_key
    RubyLLM.configure { |c| c.mistral_api_key = nil }

    service = NewsletterContentService.new
    assert_nil service.generate_news
  ensure
    RubyLLM.configure { |c| c.mistral_api_key = original_mistral }
  end

  test "excludes archived emails" do
    create_cached_email(subject: "Active News", received_at: 1.hour.ago, status: :unread)
    create_cached_email(
      zoho_message_id: "archived_msg",
      subject: "Archived News",
      received_at: 1.hour.ago,
      status: :archived
    )

    captured_prompt = nil
    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) do |prompt|
      captured_prompt = prompt
      OpenStruct.new(content: "<h2>News</h2><p>Content</p>")
    end

    service = NewsletterContentService.new(chat: fake_chat)
    service.generate_news

    assert_includes captured_prompt, "Active News"
    assert_not_includes captured_prompt, "Archived News"
  end

  test "handles LLM errors gracefully" do
    create_cached_email(received_at: 1.hour.ago)

    failing_chat = Object.new
    failing_chat.define_singleton_method(:ask) { |_| raise StandardError, "LLM down" }

    service = NewsletterContentService.new(chat: failing_chat)
    assert_nil service.generate_news
  end

  test "strips code fences from LLM response" do
    create_cached_email(received_at: 1.hour.ago)

    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) do |_|
      OpenStruct.new(content: "```html\n<h2>News</h2><p>Content</p>\n```")
    end

    service = NewsletterContentService.new(chat: fake_chat)
    result = service.generate_news

    assert_not_includes result, "```"
    assert_includes result, "<h2>News</h2>"
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
end
