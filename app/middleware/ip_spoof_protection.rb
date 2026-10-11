class IpSpoofProtection
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue ActionDispatch::RemoteIp::IpSpoofAttackError
    [ 403, { "Content-Type" => "text/plain" }, [ "Forbidden" ] ]
  end
end
