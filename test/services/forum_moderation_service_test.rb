require "test_helper"

class ForumModerationServiceTest < ActiveSupport::TestCase
  setup do
    # Create ethics page
    Page.find_or_create_by!(slug: "ethics") do |p|
      p.title = "Ethics Code"
      p.visibility = :published
      p.content = <<~HTML
        <h2>NCF Ethics Code</h2>
        <ul>
          <li>We welcome all people regardless of background</li>
          <li>We listen with openness and speak with kindness</li>
          <li>We do not tolerate content that promotes hatred or discrimination</li>
        </ul>
      HTML
    end
  end

  test "returns approved when LLM is not configured" do
    # Temporarily clear API keys
    original_openai = RubyLLM.config.openai_api_key
    original_anthropic = RubyLLM.config.anthropic_api_key

    RubyLLM.configure do |config|
      config.openai_api_key = nil
      config.anthropic_api_key = nil
    end

    service = ForumModerationService.new(content: "Hello everyone!")
    result = service.check

    assert result.approved?
    assert_equal "LLM not configured", result.reason

    # Restore
    RubyLLM.configure do |config|
      config.openai_api_key = original_openai
      config.anthropic_api_key = original_anthropic
    end
  end

  test "ethics_code is loaded from page" do
    service = ForumModerationService.new(content: "test")

    # Access private method for testing
    ethics = service.send(:ethics_code)

    assert_includes ethics, "welcome all people"
    assert_includes ethics, "hatred or discrimination"
  end

  test "parse_response handles APPROVED response" do
    service = ForumModerationService.new(content: "test")

    result = service.send(:parse_response, "APPROVED - This is a friendly greeting")

    assert result.approved?
    assert_equal "This is a friendly greeting", result.reason
  end

  test "parse_response handles REJECTED response" do
    service = ForumModerationService.new(content: "test")

    result = service.send(:parse_response, "REJECTED - Contains discriminatory language")

    assert_not result.approved?
    assert_equal "Contains discriminatory language", result.reason
  end

  test "parse_response handles ambiguous response" do
    service = ForumModerationService.new(content: "test")

    result = service.send(:parse_response, "Maybe this is okay?")

    assert_not result.approved?
    assert_equal "Moderation result unclear - flagged for review", result.reason
  end

  test "parse_response handles empty response" do
    service = ForumModerationService.new(content: "test")

    result = service.send(:parse_response, "")

    assert_not result.approved?
  end

  test "prompt includes title when provided" do
    service = ForumModerationService.new(content: "Hello", title: "My First Post")

    prompt = service.send(:prompt)

    assert_includes prompt, "Title: My First Post"
    assert_includes prompt, "Content: Hello"
  end

  test "prompt excludes title when not provided" do
    service = ForumModerationService.new(content: "Hello")

    prompt = service.send(:prompt)

    assert_not_includes prompt, "Title:"
    assert_includes prompt, "Content: Hello"
  end

  test "uses default ethics code when page not found" do
    Page.find_by(slug: "ethics")&.destroy

    service = ForumModerationService.new(content: "test")
    ethics = service.send(:ethics_code)

    assert_includes ethics, "NCF Ethics Code"
    assert_includes ethics, "hatred or discrimination"
  end
end
