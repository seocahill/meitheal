require "test_helper"

class ZohoMailServiceTest < ActiveSupport::TestCase
  setup do
    @service = ZohoMailService.new

    # Inject a pre-built connection so we skip OAuth token fetching
    fake_connection = Object.new
    @service.instance_variable_set(:@connection, fake_connection)
    @fake_connection = fake_connection
  end

  test "wraps Faraday::ConnectionFailed as ApiError" do
    @fake_connection.define_singleton_method(:get) do |_path, &_block|
      raise Faraday::ConnectionFailed, "Connection reset by peer - SSL_connect"
    end

    assert_raises(ZohoMailService::ApiError) do
      @service.folders
    end
  end

  test "wraps Faraday::TimeoutError as ApiError" do
    @fake_connection.define_singleton_method(:get) do |_path, &_block|
      raise Faraday::TimeoutError
    end

    assert_raises(ZohoMailService::ApiError) do
      @service.folders
    end
  end
end
