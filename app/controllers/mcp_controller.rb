# The MCP endpoint for the claude.ai connector. Stateless Streamable HTTP:
# Claude POSTs JSON-RPC, we hand it to the MCP server and return its JSON.
# Protected by a Doorkeeper access token carrying the mcp:access scope.
class McpController < ActionController::Base
  skip_forgery_protection
  before_action :require_mcp_token

  def invoke
    unless request.post?
      response.set_header("Allow", "POST")
      return head(:method_not_allowed)
    end

    result = mcp_server.handle_json(request.body.read)
    if result
      render json: result
    else
      head :accepted
    end
  end

  private

  def mcp_server
    Mcp::Server.build(current_resource_owner)
  end

  def current_resource_owner
    User.find_by(id: doorkeeper_token&.resource_owner_id)
  end

  def require_mcp_token
    return if doorkeeper_token&.acceptable?("mcp:access")

    response.set_header("WWW-Authenticate", %(Bearer resource_metadata="#{oauth_protected_resource_url}"))
    render json: { error: "invalid_token" }, status: :unauthorized
  end
end
