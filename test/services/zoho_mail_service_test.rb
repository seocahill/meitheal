require "test_helper"

class ZohoMailServiceTest < ActiveSupport::TestCase
  setup do
    @service = ZohoMailService.new
    @service.instance_variable_set(:@client_id, "fake-client-id")
    @service.instance_variable_set(:@client_secret, "fake-secret")
    @service.instance_variable_set(:@refresh_token, "fake-refresh-token")
    @service.instance_variable_set(:@account_id, "123456")
    @service.instance_variable_set(:@region, :eu)
  end

  test "wraps Faraday::ConnectionFailed as ApiError" do
    stub_connection_with_error(Faraday::ConnectionFailed.new("Connection reset by peer - SSL_connect"))

    error = assert_raises ZohoMailService::ApiError do
      @service.folders
    end
    assert_match "Connection reset by peer", error.message
  end

  test "wraps Faraday::TimeoutError as ApiError" do
    stub_connection_with_error(Faraday::TimeoutError.new("timeout"))

    error = assert_raises ZohoMailService::ApiError do
      @service.folders
    end
    assert_match "timeout", error.message
  end

  private

  def stub_connection_with_error(error)
    fake_connection = Object.new
    fake_connection.define_singleton_method(:get) { |*_args, &_block| raise error }
    @service.instance_variable_set(:@connection, fake_connection)
  end
end
