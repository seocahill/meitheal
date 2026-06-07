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

  test "build_template returns unsaved newsletter with default subject" do
    newsletter = Newsletter.build_template
    assert newsletter.new_record?
    assert_equal "#{Date.current.strftime('%B %Y')} Newsletter", newsletter.subject
  end

  test "build_template includes editorial placeholder" do
    newsletter = Newsletter.build_template
    assert_includes newsletter.content.to_s, "From the Editors"
  end

  test "build_template includes upcoming published events" do
    event = events(:published_event)
    newsletter = Newsletter.build_template
    assert_includes newsletter.content.to_s, "Upcoming Events"
    assert_includes newsletter.content.to_s, event.title
  end

  test "build_template excludes draft events" do
    draft = events(:draft_event)
    newsletter = Newsletter.build_template
    refute_includes newsletter.content.to_s, draft.title
  end

  test "build_template includes approved open funding opportunities" do
    grant = funding_opportunities(:arts_council_grant)
    newsletter = Newsletter.build_template
    assert_includes newsletter.content.to_s, "Funding Opportunities"
    assert_includes newsletter.content.to_s, grant.title
  end

  test "build_template excludes expired funding opportunities" do
    expired = funding_opportunities(:expired_grant)
    newsletter = Newsletter.build_template
    refute_includes newsletter.content.to_s, expired.title
  end

  test "build_template excludes pending funding opportunities" do
    pending_grant = funding_opportunities(:pending_grant)
    newsletter = Newsletter.build_template
    refute_includes newsletter.content.to_s, pending_grant.title
  end

  test "build_template includes generating news placeholder" do
    newsletter = Newsletter.build_template
    assert_includes newsletter.content.to_s, "<h2>News</h2>"
    assert_includes newsletter.content.to_s, "[Generating news section...]"
  end

  test "build_template omits events section when none upcoming" do
    Event.where(published: true).update_all(starts_at: 1.day.ago)
    newsletter = Newsletter.build_template
    refute_includes newsletter.content.to_s, "Upcoming Events"
  end

  test "build_template omits funding section when none open" do
    FundingOpportunity.update_all(deadline: 1.day.ago)
    newsletter = Newsletter.build_template
    refute_includes newsletter.content.to_s, "Funding Opportunities"
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

  test "destroying a chat nullifies newsletter chat_id without raising FK error" do
    model = Model.create!(model_id: "test-model", provider: "test", name: "Test Model")
    chat = Chat.create!(model: model)
    newsletter = Newsletter.create!(subject: "Test", content: "Content", chat: chat)

    assert_nothing_raised { chat.destroy! }
    assert_nil newsletter.reload.chat_id
  end
end
