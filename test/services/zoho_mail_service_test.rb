require "test_helper"

class ZohoMailServiceTest < ActiveSupport::TestCase
  setup do
    @service = ZohoMailService.new
    @service.instance_variable_set(:@region, :eu)
    @service.instance_variable_set(:@client_id, "test_client_id")
    @service.instance_variable_set(:@client_secret, "test_secret")
    @service.instance_variable_set(:@refresh_token, "test_refresh")
    @service.instance_variable_set(:@account_id, "123456789")
    # Skip OAuth by injecting a token directly
    @service.instance_variable_set(:@access_token, "test_access_token")
  end

  test "folders wraps Faraday::ConnectionFailed as ApiError" do
    stub_request(:get, "https://mail.zoho.eu/api/accounts/123456789/folders")
      .to_raise(Errno::ECONNRESET)

    assert_raises(ZohoMailService::ApiError) do
      @service.folders
    end
  end

  test "folders wraps Faraday::TimeoutError as ApiError" do
    stub_request(:get, "https://mail.zoho.eu/api/accounts/123456789/folders")
      .to_raise(Faraday::TimeoutError)

    assert_raises(ZohoMailService::ApiError) do
      @service.folders
    end
  end
end
