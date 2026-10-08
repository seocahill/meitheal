require "test_helper"

class RemoteIpTest < ActionDispatch::IntegrationTest
  # Kamal Proxy sets HTTP_CLIENT_IP to 127.0.0.1 (its own loopback within Docker)
  # while X-Forwarded-For carries the real client IP + the Docker bridge IP.
  # Rails' RemoteIp middleware falsely treats this mismatch as an IP spoofing
  # attack. This test ensures we've disabled that false-positive check.
  test "proxy setting HTTP_CLIENT_IP to its loopback does not raise IpSpoofAttackError" do
    get "/up", headers: {
      "HTTP_CLIENT_IP" => "127.0.0.1",
      "HTTP_X_FORWARDED_FOR" => "93.123.109.165, 172.18.0.2"
    }
    assert_response :success
  end
end
