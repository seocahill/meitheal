require "test_helper"

class BrevoServiceTest < ActiveSupport::TestCase
  test "add_contact raises ConfigurationError when not configured" do
    service = BrevoService.new
    service.instance_variable_set(:@api_key, nil)

    assert_raises(BrevoService::ConfigurationError) do
      service.add_contact("test@example.com")
    end
  end

  test "add_contact builds CreateContact with correct email and list_id" do
    captured = nil
    with_stubbed_brevo(-> (contact) { captured = contact; OpenStruct.new(id: 1) }) do |service|
      service.add_contact("test@example.com")
    end

    assert_equal "test@example.com", captured.email
    assert_equal [ 1 ], captured.list_ids
    assert_equal true, captured.update_enabled
    assert_equal({}, captured.attributes)
  end

  test "add_contact sets FIRSTNAME attribute when name provided" do
    captured = nil
    with_stubbed_brevo(-> (contact) { captured = contact; OpenStruct.new(id: 1) }) do |service|
      service.add_contact("test@example.com", name: "Jane")
    end

    assert_equal({ "FIRSTNAME" => "Jane" }, captured.attributes)
  end

  test "add_contact wraps Brevo::ApiError as BrevoService::ApiError" do
    error_handler = -> (_) { raise Brevo::ApiError.new(code: 400, response_body: '{"message":"Invalid email"}') }

    error = assert_raises(BrevoService::ApiError) do
      with_stubbed_brevo(error_handler) do |service|
        service.add_contact("bad-email")
      end
    end

    assert_equal "Invalid email", error.message
  end

  test "sent_campaigns returns campaigns from API" do
    # The real API returns campaign list items as Hashes with symbol keys
    fake_campaign = { id: 42, subject: "Test", sentDate: "2026-01-15" }
    fake_response = OpenStruct.new(campaigns: [ fake_campaign ])

    with_stubbed_campaigns_api(get_email_campaigns: fake_response) do |service|
      result = service.sent_campaigns
      assert_equal 1, result.size
      assert_equal 42, result.first[:id]
    end
  end

  test "strip_email_wrapper extracts body content from full HTML email" do
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>body { font-family: sans-serif; }</style>
      </head>
      <body>
        <h1>Hello World</h1>
        <p>Newsletter content here.</p>
      </body>
      </html>
    HTML

    result = BrevoService.strip_email_wrapper(html)
    assert_includes result, "<h1>Hello World</h1>"
    assert_includes result, "<p>Newsletter content here.</p>"
    refute_includes result, "<!DOCTYPE"
    refute_includes result, "<html"
    refute_includes result, "<head"
    refute_includes result, "<style"
    refute_includes result, "</html>"
  end

  test "strip_email_wrapper removes unsubscribe footer" do
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <body>
        <p>Content</p>
        <hr style="margin-top: 40px;">
        <p style="font-size: 12px;">
          You're receiving this because you're subscribed.<br>
          <a href="{{ unsubscribe }}">Unsubscribe</a>
        </p>
      </body>
      </html>
    HTML

    result = BrevoService.strip_email_wrapper(html)
    assert_includes result, "<p>Content</p>"
    refute_includes result, "unsubscribe"
    refute_includes result, "You're receiving this"
  end

  test "strip_email_wrapper returns content as-is when no wrapper present" do
    html = "<h2>Just a heading</h2><p>Some text</p>"
    result = BrevoService.strip_email_wrapper(html)
    assert_includes result, "<h2>Just a heading</h2>"
    assert_includes result, "<p>Some text</p>"
  end

  test "strip_email_wrapper handles nil gracefully" do
    assert_equal "", BrevoService.strip_email_wrapper(nil)
  end

  test "strip_email_wrapper handles empty string" do
    assert_equal "", BrevoService.strip_email_wrapper("")
  end

  test "campaign_content returns single campaign details" do
    fake_campaign = OpenStruct.new(id: 42, subject: "Test", html_content: "<p>Content</p>", sent_date: "2026-01-15")

    with_stubbed_campaigns_api(get_email_campaign: fake_campaign) do |service|
      result = service.campaign_content(42)
      assert_equal "<p>Content</p>", result.html_content
    end
  end

  test "list_contacts returns contacts from configured list" do
    fake_contacts = [
      OpenStruct.new(email: "alice@example.com", attributes: { "FIRSTNAME" => "Alice" }),
      OpenStruct.new(email: "bob@example.com", attributes: { "FIRSTNAME" => "Bob" })
    ]
    fake_response = OpenStruct.new(contacts: fake_contacts)

    with_stubbed_contacts_api(get_contacts_from_list: fake_response) do |service|
      result = service.list_contacts(limit: 500, offset: 0)
      assert_equal 2, result.size
      assert_equal "alice@example.com", result.first.email
    end
  end

  private

  def with_stubbed_contacts_api(responses = {})
    fake_contacts_api = Object.new
    responses.each do |method, response|
      fake_contacts_api.define_singleton_method(method) { |*_args, **_opts| response }
    end

    service = BrevoService.new
    service.instance_variable_set(:@api_key, "test-key")
    service.instance_variable_set(:@sender_email, "test@example.com")
    service.instance_variable_set(:@list_id, 1)
    service.instance_variable_set(:@contacts_api, fake_contacts_api)

    yield service
  end

  def with_stubbed_campaigns_api(responses = {})
    fake_campaigns_api = Object.new
    responses.each do |method, response|
      fake_campaigns_api.define_singleton_method(method) { |*_args, **_opts| response }
    end

    service = BrevoService.new
    service.instance_variable_set(:@api_key, "test-key")
    service.instance_variable_set(:@sender_email, "test@example.com")
    service.instance_variable_set(:@list_id, 1)
    service.instance_variable_set(:@campaigns_api, fake_campaigns_api)

    yield service
  end

  def with_stubbed_brevo(create_contact_handler)
    fake_contacts_api = Object.new
    fake_contacts_api.define_singleton_method(:create_contact) { |contact| create_contact_handler.call(contact) }

    service = BrevoService.new
    service.instance_variable_set(:@api_key, "test-key")
    service.instance_variable_set(:@sender_email, "test@example.com")
    service.instance_variable_set(:@list_id, 1)
    service.instance_variable_set(:@contacts_api, fake_contacts_api)

    yield service
  end
end
