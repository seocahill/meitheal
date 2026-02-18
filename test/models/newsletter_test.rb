require "test_helper"

class NewsletterTest < ActiveSupport::TestCase
  test "valid newsletter with required attributes" do
    newsletter = Newsletter.new(
      subject: "Monthly Update",
      content: "Hello members..."
    )
    assert newsletter.valid?
  end

  test "requires subject" do
    newsletter = Newsletter.new(content: "Content")
    assert_not newsletter.valid?
    assert_includes newsletter.errors[:subject], "can't be blank"
  end

  test "requires content" do
    newsletter = Newsletter.new(subject: "Subject")
    assert_not newsletter.valid?
    assert_includes newsletter.errors[:content], "can't be blank"
  end

  test "status defaults to draft" do
    newsletter = Newsletter.new(subject: "Test", content: "Content")
    assert newsletter.draft?
  end

  test "can transition from draft to sent" do
    newsletter = Newsletter.create!(subject: "Test", content: "Content")
    assert newsletter.draft?
    newsletter.mark_sent!
    assert newsletter.sent?
    assert_not_nil newsletter.sent_at
  end

  test "draft scope returns only drafts" do
    draft = Newsletter.create!(subject: "Draft", content: "Content", status: :draft)
    sent = Newsletter.create!(subject: "Sent", content: "Content", status: :sent, sent_at: Time.current)

    assert_includes Newsletter.draft, draft
    assert_not_includes Newsletter.draft, sent
  end

  test "sent scope returns only sent newsletters" do
    draft = Newsletter.create!(subject: "Draft", content: "Content", status: :draft)
    sent = Newsletter.create!(subject: "Sent", content: "Content", status: :sent, sent_at: Time.current)

    assert_includes Newsletter.sent, sent
    assert_not_includes Newsletter.sent, draft
  end

  test "has rich text content" do
    newsletter = Newsletter.create!(subject: "Rich", content: "<p>Rich content</p>")
    assert newsletter.content.present?
  end

  test "belongs to optional chat for LLM assistance" do
    newsletter = Newsletter.create!(subject: "Test", content: "Content")
    assert_nil newsletter.chat

    # Use a Claude model from the registry
    model = Model.find_by(model_id: "claude-3-5-haiku-20241022")
    skip "No Claude model in test database" unless model
    chat = Chat.create!(model: model)
    newsletter.update!(chat: chat)
    assert_equal chat, newsletter.chat
  end
end
