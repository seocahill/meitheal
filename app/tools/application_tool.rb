# Base class for all MCP tools. Inherits the Rails-friendly ActionTool::Base
# alias that fast-mcp installs (== FastMcp::Tool). Tools placed in app/tools are
# auto-registered with the MCP server mounted in config/initializers/fast_mcp.rb.
class ApplicationTool < ActionTool::Base
end
