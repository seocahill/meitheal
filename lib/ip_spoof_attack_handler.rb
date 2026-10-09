class IpSpoofAttackHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue ActionDispatch::RemoteIp::IpSpoofAttackError
    [400, { "Content-Type" => "text/plain" }, ["Bad Request"]]
  end
end
