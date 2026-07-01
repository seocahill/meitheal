# Base class for all MCP tools. Inherits the Rails-friendly ActionTool::Base
# alias that fast-mcp installs (== FastMcp::Tool). Tools placed in app/tools are
# auto-registered with the MCP server mounted in config/initializers/fast_mcp.rb.
class ApplicationTool < ActionTool::Base
  private

  # Records created over MCP have no session user, so they are attributed to the
  # owner account. Tools that need an owner should fail clearly when none exists.
  def owner_user
    User.owner.order(:id).first
  end
end
