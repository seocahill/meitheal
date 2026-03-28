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
    fake_campaign = OpenStruct.new(id: 42, subject: "Test", sent_date: "2026-01-15", html_content: "<p>Hi</p>")
    fake_response = OpenStruct.new(campaigns: [ fake_campaign ])

    with_stubbed_campaigns_api(get_email_campaigns: fake_response) do |service|
      result = service.sent_campaigns
      assert_equal 1, result.size
      assert_equal 42, result.first.id
    end
  end

  test "campaign_content returns single campaign details" do
    fake_campaign = OpenStruct.new(id: 42, subject: "Test", html_content: "<p>Content</p>", sent_date: "2026-01-15")

    with_stubbed_campaigns_api(get_email_campaign: fake_campaign) do |service|
      result = service.campaign_content(42)
      assert_equal "<p>Content</p>", result.html_content
    end
  end

  private

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
