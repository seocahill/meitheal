require "test_helper"

class ArchiveEmailToolTest < ActiveSupport::TestCase
  test "archives the email with the given id" do
    email = cached_email(subject: "Spammy digest")

    output = ArchiveEmailTool.new.call(id: email.id)

    assert_predicate email.reload, :archived?
    assert_match "Spammy digest", output
  end

  test "reports when no email matches the id" do
    assert_match(/no email found/i, ArchiveEmailTool.new.call(id: 999_999))
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
