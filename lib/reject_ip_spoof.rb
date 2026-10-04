# Clients sending conflicting Client-IP and X-Forwarded-For headers (a common
# bot probe) trigger ActionDispatch::RemoteIp::IpSpoofAttackError in the
# Rails::Rack::Logger before ShowExceptions or rescue_from can handle it.
# This middleware sits above the logger and returns 400 instead.
class RejectIpSpoof
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue ActionDispatch::RemoteIp::IpSpoofAttackError
    [ 400, { "Content-Type" => "text/plain" }, [ "Bad Request" ] ]
  end
end
