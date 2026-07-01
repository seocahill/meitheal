require "test_helper"

class CreateNewsletterToolTest < ActiveSupport::TestCase
  test "creates a draft newsletter from subject and content" do
    assert_difference -> { Newsletter.count }, 1 do
      CreateNewsletterTool.new.call(subject: "July News", content: "<h2>Hello</h2>")
    end

    newsletter = Newsletter.order(:created_at).last
    assert_equal "July News", newsletter.subject
    assert_predicate newsletter, :draft?
    assert_match "Hello", newsletter.content.to_plain_text
  end
end
