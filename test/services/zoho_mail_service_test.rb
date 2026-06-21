require "test_helper"

class ZohoMailServiceTest < ActiveSupport::TestCase
  setup do
    @service = ZohoMailService.new
    @service.instance_variable_set(:@client_id, "test_client_id")
    @service.instance_variable_set(:@client_secret, "test_client_secret")
    @service.instance_variable_set(:@refresh_token, "test_refresh_token")
    @service.instance_variable_set(:@account_id, "test_account_id")
    @service.instance_variable_set(:@access_token, "test_token")
    @service.instance_variable_set(:@region, :eu)
  end

  test "wraps Faraday::ConnectionFailed as ApiError" do
    stub_request(:get, "https://mail.zoho.eu/api/accounts/test_account_id/folders")
      .to_raise(Faraday::ConnectionFailed.new(RuntimeError.new("Connection reset by peer - SSL_connect")))

    assert_raises(ZohoMailService::ApiError) do
      @service.folders
    end
  end
end
