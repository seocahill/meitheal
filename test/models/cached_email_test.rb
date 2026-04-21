require "test_helper"

class CachedEmailTest < ActiveSupport::TestCase
  test "valid with all required attributes" do
    email = CachedEmail.new(
      zoho_message_id: "msg_123",
      zoho_folder_id: "folder_456",
      from_address: "sender@example.com",
      subject: "Test Email",
      received_at: 1.hour.ago
    )
    assert email.valid?
  end

  test "requires zoho_message_id" do
    email = CachedEmail.new(
      zoho_folder_id: "folder_456",
      from_address: "sender@example.com",
      subject: "Test",
      received_at: 1.hour.ago
    )
    assert_not email.valid?
    assert_includes email.errors[:zoho_message_id], "can't be blank"
  end

  test "requires unique zoho_message_id" do
    CachedEmail.create!(
      zoho_message_id: "msg_unique",
      zoho_folder_id: "folder_456",
      from_address: "sender@example.com",
      subject: "First",
      received_at: 1.hour.ago
    )
    duplicate = CachedEmail.new(
      zoho_message_id: "msg_unique",
      zoho_folder_id: "folder_456",
      from_address: "other@example.com",
      subject: "Second",
      received_at: Time.current
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:zoho_message_id], "has already been taken"
  end

  test "requires from_address" do
    email = CachedEmail.new(
      zoho_message_id: "msg_123",
      zoho_folder_id: "folder_456",
      subject: "Test",
      received_at: 1.hour.ago
    )
    assert_not email.valid?
    assert_includes email.errors[:from_address], "can't be blank"
  end

  test "requires subject" do
    email = CachedEmail.new(
      zoho_message_id: "msg_123",
      zoho_folder_id: "folder_456",
      from_address: "sender@example.com",
      received_at: 1.hour.ago
    )
    assert_not email.valid?
    assert_includes email.errors[:subject], "can't be blank"
  end

  test "requires received_at" do
    email = CachedEmail.new(
      zoho_message_id: "msg_123",
      zoho_folder_id: "folder_456",
      from_address: "sender@example.com",
      subject: "Test"
    )
    assert_not email.valid?
    assert_includes email.errors[:received_at], "can't be blank"
  end

  test "status defaults to unread" do
    email = CachedEmail.new(
      zoho_message_id: "msg_123",
      zoho_folder_id: "folder_456",
      from_address: "sender@example.com",
      subject: "Test",
      received_at: 1.hour.ago
    )
    assert email.unread?
  end

  test "status enum values" do
    email = CachedEmail.create!(
      zoho_message_id: "msg_enum",
      zoho_folder_id: "folder_456",
      from_address: "sender@example.com",
      subject: "Test",
      received_at: 1.hour.ago
    )

    assert email.unread?

    email.read!
    assert email.read?

    email.archived!
    assert email.archived?
  end

  test "recent scope returns emails from last 30 days ordered by received_at desc" do
    old = CachedEmail.create!(
      zoho_message_id: "msg_old",
      zoho_folder_id: "folder_456",
      from_address: "sender@example.com",
      subject: "Old Email",
      received_at: 60.days.ago
    )
    recent = CachedEmail.create!(
      zoho_message_id: "msg_recent",
      zoho_folder_id: "folder_456",
      from_address: "sender@example.com",
      subject: "Recent Email",
      received_at: 2.days.ago
    )
    newest = CachedEmail.create!(
      zoho_message_id: "msg_newest",
      zoho_folder_id: "folder_456",
      from_address: "sender@example.com",
      subject: "Newest Email",
      received_at: 1.hour.ago
    )

    results = CachedEmail.recent
    assert_includes results, recent
    assert_includes results, newest
    assert_not_includes results, old
    assert_equal newest, results.first
  end

  test "can have attachments via Active Storage" do
    email = CachedEmail.create!(
      zoho_message_id: "msg_attach",
      zoho_folder_id: "folder_456",
      from_address: "sender@example.com",
      subject: "With attachments",
      received_at: 1.hour.ago
    )
    email.attachments.attach(
      io: StringIO.new("file content"),
      filename: "test.pdf",
      content_type: "application/pdf"
    )
    assert_equal 1, email.attachments.count
    assert_equal "test.pdf", email.attachments.first.filename.to_s
  end

  test "displayable_body strips Zoho inline image references" do
    body = '<p>Hello</p><img src="/mail/ImageDisplay?na=123&nmsgId=456&f=1.png&mode=inline&cid=ii_abc"><p>Bye</p>'
    email = CachedEmail.new(body: body)
    result = email.displayable_body
    assert_no_match "ImageDisplay", result
    assert_no_match "<img", result
    assert_match "<p>Hello</p>", result
    assert_match "<p>Bye</p>", result
  end

  test "displayable_body preserves externally-hosted images" do
    body = '<p>Content</p><img src="https://example.com/image.jpg" alt="poster">'
    email = CachedEmail.new(body: body)
    assert_includes email.displayable_body, "https://example.com/image.jpg"
  end

  test "displayable_body returns body unchanged when no inline images" do
    body = "<p>Plain text email</p>"
    email = CachedEmail.new(body: body)
    assert_equal body, email.displayable_body
  end

  test "displayable_body handles nil body" do
    email = CachedEmail.new(body: nil)
    assert_nil email.displayable_body
  end

  test "visible scope excludes archived emails" do
    visible = CachedEmail.create!(
      zoho_message_id: "msg_visible",
      zoho_folder_id: "folder_456",
      from_address: "sender@example.com",
      subject: "Visible",
      received_at: 1.hour.ago,
      status: :unread
    )
    archived = CachedEmail.create!(
      zoho_message_id: "msg_archived",
      zoho_folder_id: "folder_456",
      from_address: "sender@example.com",
      subject: "Archived",
      received_at: 1.hour.ago,
      status: :archived
    )

    results = CachedEmail.visible
    assert_includes results, visible
    assert_not_includes results, archived
  end
end
