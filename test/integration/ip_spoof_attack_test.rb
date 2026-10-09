require "test_helper"

# Reproduces the Sentry issue: bots sending Client-IP: 127.0.0.1 while
# X-Forwarded-For contains a real external IP, triggering Rails' spoof
# detection. This should return 400 Bad Request, not 500.
class IpSpoofAttackTest < ActionDispatch::IntegrationTest
  test "spoofed Client-IP header returns 400, not 500" do
    get "/up", env: {
      "HTTP_CLIENT_IP" => "127.0.0.1",
      "HTTP_X_FORWARDED_FOR" => "93.123.109.165, 172.18.0.2"
    }
    assert_response :bad_request
  end
end
