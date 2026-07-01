require "test_helper"

class CreateEventToolTest < ActiveSupport::TestCase
  test "creates an unpublished event owned by the owner account" do
    assert_difference -> { Event.count }, 1 do
      CreateEventTool.new.call(title: "Spring Show", starts_at: "2026-05-01 19:30")
    end

    event = Event.order(:created_at).last
    assert_equal "Spring Show", event.title
    assert_not event.published?, "MCP-created events must await publishing"
    assert_equal users(:owner), event.user
    assert_equal Time.zone.parse("2026-05-01 19:30"), event.starts_at
  end

  test "copies the first image attachment from a source email" do
    email = cached_email
    email.attachments.attach(io: StringIO.new("fake-png"), filename: "poster.png", content_type: "image/png")

    CreateEventTool.new.call(title: "With Poster", starts_at: "2026-05-01 19:30", from_email_id: email.id)

    event = Event.order(:created_at).last
    assert event.image.attached?
    assert_equal "poster.png", event.image.filename.to_s
  end

  test "ignores non-image attachments when sourcing an image" do
    email = cached_email
    email.attachments.attach(io: StringIO.new("data"), filename: "notes.pdf", content_type: "application/pdf")

    CreateEventTool.new.call(title: "No Poster", starts_at: "2026-05-01 19:30", from_email_id: email.id)

    assert_not Event.order(:created_at).last.image.attached?
  end

  test "rejects an unparseable start time without creating an event" do
    assert_no_difference -> { Event.count } do
      output = CreateEventTool.new.call(title: "Bad", starts_at: "not-a-time")
      assert_match(/invalid start/i, output)
    end
  end

  private

  def cached_email(attrs = {})
    CachedEmail.create!({
      zoho_message_id: "msg_#{SecureRandom.hex(4)}",
      zoho_folder_id: "folder_inbox",
      from_address: "sender@example.com",
      subject: "Test",
      received_at: 1.hour.ago
    }.merge(attrs))
  end
end
