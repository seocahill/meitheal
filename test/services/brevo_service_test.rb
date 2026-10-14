require "test_helper"
require "ostruct"

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
    with_stubbed_brevo(->(contact) { captured = contact; OpenStruct.new(id: 1) }) do |service|
      service.add_contact("test@example.com")
    end

    assert_equal "test@example.com", captured.email
    assert_equal [ 1 ], captured.list_ids
    assert_equal true, captured.update_enabled
    assert_equal({}, captured.attributes)
  end

  test "add_contact sets FIRSTNAME attribute when name provided" do
    captured = nil
    with_stubbed_brevo(->(contact) { captured = contact; OpenStruct.new(id: 1) }) do |service|
      service.add_contact("test@example.com", name: "Jane")
    end

    assert_equal({ "FIRSTNAME" => "Jane" }, captured.attributes)
  end

  test "add_contact wraps Brevo::ApiError as BrevoService::ApiError" do
    error_handler = ->(_) { raise Brevo::ApiError.new(code: 400, response_body: '{"message":"Invalid email"}') }

    error = assert_raises(BrevoService::ApiError) do
      with_stubbed_brevo(error_handler) do |service|
        service.add_contact("bad-email")
      end
    end

    assert_equal "Invalid email", error.message
  end

  test "sent_campaigns asks Brevo for sent campaigns newest first without HTML bodies" do
    captured = []
    fake_response = OpenStruct.new(campaigns: [ { id: 42, subject: "Test" } ])

    with_stubbed_campaigns_api(get_email_campaigns: ->(opts) { captured << opts; fake_response }) do |service|
      assert_equal [ { id: 42, subject: "Test" } ], service.sent_campaigns
    end

    assert_equal 1, captured.size
    assert_equal "sent", captured.first[:status]
    assert_equal "desc", captured.first[:sort]
    assert_equal true, captured.first[:exclude_html_content]
    assert_equal 0, captured.first[:offset]
  end

  test "sent_campaigns reads every page, not just the first" do
    offsets = []
    pages = {
      0 => Array.new(100) { |i| { id: i } },
      100 => Array.new(100) { |i| { id: 100 + i } },
      200 => [ { id: 200 }, { id: 201 } ]
    }

    with_stubbed_campaigns_api(get_email_campaigns: ->(opts) { offsets << opts[:offset]; OpenStruct.new(campaigns: pages.fetch(opts[:offset])) }) do |service|
      assert_equal 202, service.sent_campaigns.size
    end

    assert_equal [ 0, 100, 200 ], offsets
  end

  test "sent_campaigns stops after a page that comes back empty" do
    offsets = []
    with_stubbed_campaigns_api(get_email_campaigns: ->(opts) { offsets << opts[:offset]; OpenStruct.new(campaigns: nil) }) do |service|
      assert_equal [], service.sent_campaigns
    end
    assert_equal [ 0 ], offsets
  end

  test "sent_campaigns raises ConfigurationError when not configured" do
    service = BrevoService.new
    service.instance_variable_set(:@api_key, nil)
    assert_raises(BrevoService::ConfigurationError) { service.sent_campaigns }
  end

  test "sent_campaigns wraps Brevo::ApiError as BrevoService::ApiError" do
    error = Brevo::ApiError.new(code: 500, response_body: { message: "boom" }.to_json)
    with_stubbed_campaigns_api(get_email_campaigns: ->(_opts) { raise error }) do |service|
      assert_raises(BrevoService::ApiError) { service.sent_campaigns }
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

  def with_stubbed_campaigns_api(handlers)
    fake_campaigns_api = Object.new
    handlers.each do |method, handler|
      fake_campaigns_api.define_singleton_method(method) { |opts = {}| handler.call(opts) }
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
