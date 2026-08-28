require "test_helper"

# Regression test for THENCF-X: WordPress bots send Client-IP: 127.0.0.1 alongside
# X-Forwarded-For with real IPs (common behind kamal-proxy). Rails RemoteIp middleware
# raises IpSpoofAttackError when these headers disagree, causing 500s with 0 user impact.
class IpSpoofAttackTest < ActionDispatch::IntegrationTest
  test "request with mismatched CLIENT_IP and X_FORWARDED_FOR headers does not raise IpSpoofAttackError" do
    get root_path, headers: {
      "HTTP_CLIENT_IP" => "127.0.0.1",
      "HTTP_X_FORWARDED_FOR" => "45.148.10.246, 172.18.0.2"
    }
    assert_not_equal 500, response.status
  end
end
