require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  # Reproduces the Sentry issue THENCF-X: bots sending Client-IP: 127.0.0.1
  # to spoof their IP while Kamal-proxy adds the real IP in X-Forwarded-For.
  # Rails 8.1 raises IpSpoofAttackError when both headers are present and disagree.
  # We should return 400 Bad Request rather than letting it bubble as a 500.
  test "responds with bad request when Client-IP spoofing headers are detected" do
    get events_path,
      headers: {
        "Client-Ip" => "127.0.0.1",
        "X-Forwarded-For" => "93.123.109.165, 172.18.0.2"
      }

    assert_response :bad_request
  end
end
