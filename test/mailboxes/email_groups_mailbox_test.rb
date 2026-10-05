# frozen_string_literal: true

require "test_helper"

class EmailGroupsMailboxTest < ActionMailbox::TestCase
  test "processes email with UTF-16LE encoded body without raising" do
    group = email_groups(:all_members)

    utf16_body = "Hello from a Windows client".encode("UTF-16LE")
    encoded_body = Base64.strict_encode64(utf16_body)

    raw_email = <<~EMAIL
      To: #{group.email_address}
      From: sender@example.com
      Subject: Test email
      MIME-Version: 1.0
      Content-Type: text/plain; charset=UTF-16LE
      Content-Transfer-Encoding: base64

      #{encoded_body}
    EMAIL

    assert_difference "ArchivedEmail.count", 1 do
      receive_inbound_email_from_source(raw_email)
    end

    archived = ArchivedEmail.last
    assert_equal "UTF-8", archived.body.encoding.to_s
    assert_includes archived.body, "Hello from a Windows client"
  end
end
