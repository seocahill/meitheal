require "test_helper"

class NewsletterTest < ActiveSupport::TestCase
  test "sent scope returns only newsletters that were sent" do
    assert_includes Newsletter.sent, newsletters(:sent_newsletter)
    assert_not_includes Newsletter.sent, newsletters(:monthly_update)
  end

  test "content is rich text" do
    assert_includes newsletters(:sent_newsletter).content.to_s, "December was a great month"
  end
end
