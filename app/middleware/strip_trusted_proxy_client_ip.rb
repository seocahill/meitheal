# Removes HTTP_CLIENT_IP from the Rack environment when it contains a trusted
# proxy address (e.g. 127.0.0.1 set by kamal-proxy). Without this, Rails'
# RemoteIp middleware raises IpSpoofAttackError because the loopback address in
# CLIENT_IP is absent from X-Forwarded-For, triggering a false positive.
class StripTrustedProxyClientIp
  def initialize(app)
    @app = app
  end

  def call(env)
    if (raw = env["HTTP_CLIENT_IP"])
      ip = IPAddr.new(raw.strip)
      env.delete("HTTP_CLIENT_IP") if ActionDispatch::RemoteIp::TRUSTED_PROXIES.any? { |proxy| proxy === ip }
    end
    @app.call(env)
  rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
    @app.call(env)
  end
end
