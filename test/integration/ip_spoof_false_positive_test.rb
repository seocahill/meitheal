require "test_helper"

# Reproduces Sentry issue THENCF-X: kamal-proxy sets HTTP_CLIENT_IP=127.0.0.1
# while also forwarding X-Forwarded-For with the real external IP. Rails'
# RemoteIp middleware treats this as an IP spoofing attack even though 127.0.0.1
# is a trusted loopback address, because the spoofing check runs before trusted
# proxy filtering.
class IpSpoofFalsePositiveTest < ActiveSupport::TestCase
  EXTERNAL_IP = "195.178.110.132"
  DOCKER_BRIDGE_IP = "172.18.0.2"

  # Builds a minimal Rack app that forces remote_ip to be calculated,
  # mirroring the production middleware order.
  def middleware_stack
    inner = lambda { |env|
      ip = ActionDispatch::Request.new(env).remote_ip.to_s
      [200, {}, [ip]]
    }
    StripTrustedProxyClientIp.new(ActionDispatch::RemoteIp.new(inner))
  end

  def env_for(client_ip:, x_forwarded_for:)
    Rack::MockRequest.env_for("/",
      "HTTP_CLIENT_IP" => client_ip,
      "HTTP_X_FORWARDED_FOR" => x_forwarded_for
    )
  end

  test "trusted-proxy CLIENT_IP with X-Forwarded-For does not raise IpSpoofAttackError" do
    env = env_for(
      client_ip: "127.0.0.1",
      x_forwarded_for: "#{EXTERNAL_IP}, #{DOCKER_BRIDGE_IP}"
    )

    assert_nothing_raised do
      middleware_stack.call(env)
    end
  end

  test "external ip resolves correctly when CLIENT_IP is trusted loopback" do
    env = env_for(
      client_ip: "127.0.0.1",
      x_forwarded_for: "#{EXTERNAL_IP}, #{DOCKER_BRIDGE_IP}"
    )

    _status, _headers, body = middleware_stack.call(env)
    assert_equal EXTERNAL_IP, body.first
  end
end
