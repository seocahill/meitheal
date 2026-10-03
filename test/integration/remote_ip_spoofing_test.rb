require "test_helper"

# Kamal-proxy sets HTTP_CLIENT_IP to 127.0.0.1 (its internal loopback) when
# forwarding requests. Rails RemoteIp middleware then sees CLIENT_IP and
# X-Forwarded-For with mismatched IPs and raises IpSpoofAttackError, causing
# login requests to return 500 instead of authenticating the user.
class RemoteIpSpoofingTest < ActionDispatch::IntegrationTest
  test "login succeeds when kamal-proxy sets CLIENT_IP to loopback" do
    user = users(:owner)

    post session_path,
      params: { email_address: user.email_address, password: "password" },
      headers: {
        "HTTP_CLIENT_IP" => "127.0.0.1",
        "X-Forwarded-For" => "93.123.109.165, 172.18.0.2"
      }

    assert_redirected_to root_path
  end
end
