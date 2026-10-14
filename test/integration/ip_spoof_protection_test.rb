require "test_helper"

class IpSpoofProtectionTest < ActionDispatch::IntegrationTest
  test "returns 403 when CLIENT_IP and X-Forwarded-For conflict" do
    get "/", headers: {
      "HTTP_CLIENT_IP" => "127.0.0.1",
      "HTTP_X_FORWARDED_FOR" => "93.123.109.165, 172.18.0.2"
    }
    assert_response :forbidden
  end

  test "allows normal requests through" do
    get "/"
    assert_response :success
  end
end
