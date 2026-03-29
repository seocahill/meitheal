require "test_helper"

class GenerateNewsletterContentJobTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  setup do
    @newsletter = Newsletter.create!(
      subject: "March 2026 Newsletter",
      content: "<h2>From the Editors</h2><p>Placeholder</p><p>[Generating news section...]</p>"
    )

    CachedEmail.create!(
      zoho_message_id: "msg_news_001",
      zoho_folder_id: "folder_inbox",
      from_address: "gallery@example.com",
      subject: "Exhibition Opening",
      summary: "New art show next week",
      received_at: 2.hours.ago
    )
  end

  test "replaces news placeholder with generated content" do
    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) do |_|
      OpenStruct.new(content: "<h2>News</h2><p>Gallery opening next week!</p>")
    end

    original_new = NewsletterContentService.method(:new)
    NewsletterContentService.define_singleton_method(:new) do |**kwargs|
      original_new.call(chat: fake_chat, **kwargs)
    end

    GenerateNewsletterContentJob.perform_now(@newsletter)

    @newsletter.reload
    assert_includes @newsletter.content.to_s, "Gallery opening next week!"
    assert_not_includes @newsletter.content.to_s, "[Generating news section...]"
  ensure
    NewsletterContentService.define_singleton_method(:new, original_new)
  end

  test "broadcasts refresh to newsletter stream" do
    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) do |_|
      OpenStruct.new(content: "<h2>News</h2><p>Fresh content</p>")
    end

    original_new = NewsletterContentService.method(:new)
    NewsletterContentService.define_singleton_method(:new) do |**kwargs|
      original_new.call(chat: fake_chat, **kwargs)
    end

    assert_broadcasts("newsletter_#{@newsletter.id}", 1) do
      GenerateNewsletterContentJob.perform_now(@newsletter)
    end
  ensure
    NewsletterContentService.define_singleton_method(:new, original_new)
  end

  test "does not update newsletter when service returns nil" do
    original_content = @newsletter.content.to_s

    original_new = NewsletterContentService.method(:new)
    stub_service = Object.new
    stub_service.define_singleton_method(:generate_news) { nil }
    NewsletterContentService.define_singleton_method(:new) { |**_| stub_service }

    GenerateNewsletterContentJob.perform_now(@newsletter)

    @newsletter.reload
    assert_equal original_content, @newsletter.content.to_s
  ensure
    NewsletterContentService.define_singleton_method(:new, original_new)
  end

  test "does not broadcast when service returns nil" do
    original_new = NewsletterContentService.method(:new)
    stub_service = Object.new
    stub_service.define_singleton_method(:generate_news) { nil }
    NewsletterContentService.define_singleton_method(:new) { |**_| stub_service }

    assert_no_broadcasts("newsletter_#{@newsletter.id}") do
      GenerateNewsletterContentJob.perform_now(@newsletter)
    end
  ensure
    NewsletterContentService.define_singleton_method(:new, original_new)
  end
end
