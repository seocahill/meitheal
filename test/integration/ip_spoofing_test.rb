require "test_helper"

class IpSpoofingTest < ActionDispatch::IntegrationTest
  # Reproduces Sentry issue THENCF-X:
  # WordPress bots send CLIENT_IP: 127.0.0.1 which conflicts with
  # X-Forwarded-For, causing Rails to raise IpSpoofAttackError (500).
  # Since the app always runs behind kamal-proxy, ip_spoofing_check is disabled.
  test "request with conflicting CLIENT_IP and X-Forwarded-For does not raise" do
    get "/up", headers: {
      "HTTP_CLIENT_IP" => "127.0.0.1",
      "HTTP_X_FORWARDED_FOR" => "195.178.110.155, 172.18.0.2"
    }
    assert_not_equal 500, response.status
  end
end
