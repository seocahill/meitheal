require "test_helper"

class SearchEmailsToolTest < ActiveSupport::TestCase
  test "matches emails by subject, sender or summary and includes their id" do
    match = cached_email(subject: "Exhibition opening night", from_address: "gallery@example.com")
    cached_email(subject: "Unrelated invoice", from_address: "billing@example.com")

    output = SearchEmailsTool.new.call(query: "exhibition")

    assert_match "##{match.id}", output
    assert_match "Exhibition opening night", output
    assert_no_match(/Unrelated invoice/, output)
  end

  test "excludes archived emails unless include_archived is set" do
    archived = cached_email(subject: "Old exhibition", status: :archived)

    assert_no_match(/##{archived.id}\b/, SearchEmailsTool.new.call(query: "exhibition"))
    assert_match "##{archived.id}", SearchEmailsTool.new.call(query: "exhibition", include_archived: true)
  end

  test "reports when nothing matches" do
    assert_match(/no emails/i, SearchEmailsTool.new.call(query: "nothing-matches-this"))
  end

  private

  def cached_email(attrs = {})
    CachedEmail.create!({
      zoho_message_id: "msg_#{SecureRandom.hex(4)}",
      zoho_folder_id: "folder_inbox",
      from_address: "sender@example.com",
      subject: "Test",
      summary: "Test summary",
      received_at: 1.hour.ago
    }.merge(attrs))
  end
end
