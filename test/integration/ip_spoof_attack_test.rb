require "test_helper"

# Reproduces Sentry issue THENCF-X:
# WordPress scanners send Client-IP: 127.0.0.1 while the Kamal proxy adds
# X-Forwarded-For with the real external IP. Rails' RemoteIp middleware raises
# IpSpoofAttackError because the two headers disagree.
class IpSpoofAttackTest < ActionDispatch::IntegrationTest
  SPOOFED_HEADERS = {
    "HTTP_CLIENT_IP" => "127.0.0.1",
    "HTTP_X_FORWARDED_FOR" => "45.148.10.246, 172.18.0.2",
    "HTTP_FORWARDED" => "for=45.148.10.246, for=172.18.0.2"
  }.freeze

  test "requests with conflicting Client-IP and X-Forwarded-For headers are not rejected" do
    get "/up", headers: SPOOFED_HEADERS
    assert_not_equal 500, response.status
  end
end
