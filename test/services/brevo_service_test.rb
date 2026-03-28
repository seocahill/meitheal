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

  private

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
