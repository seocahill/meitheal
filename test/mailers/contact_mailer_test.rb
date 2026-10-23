require "test_helper"

class ContactMailerTest < ActionMailer::TestCase
  test "contact message is addressed to the company info account" do
    email = ContactMailer.contact_message(email: "visitor@example.com", message: "Hello")
    assert_equal [ "info@thencf.art" ], email.to
  end

  test "contact message replies to the visitor" do
    email = ContactMailer.contact_message(email: "visitor@example.com", message: "Hello")
    assert_equal [ "visitor@example.com" ], email.reply_to
  end
end
