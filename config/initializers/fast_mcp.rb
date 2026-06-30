# frozen_string_literal: true

require "fast_mcp"

# Mounts a Model Context Protocol (MCP) server that exposes the admin tools in
# app/tools to authenticated AI clients (e.g. Claude as a custom connector).
#
# The server is only mounted when MCP_AUTH_TOKEN is set, so it fails closed:
# with no token configured there is no endpoint at all. Clients authenticate by
# sending `Authorization: Bearer <MCP_AUTH_TOKEN>`.
#
# In production the host serving this must be present in config.hosts, because
# fast-mcp validates the request Origin against the Rails host allowlist.
mcp_auth_token = ENV["MCP_AUTH_TOKEN"].presence

if mcp_auth_token
  FastMcp.mount_in_rails(
    Rails.application,
    name: Rails.application.class.module_parent_name.underscore.dasherize,
    version: "1.0.0",
    authenticate: true,
    auth_token: mcp_auth_token
  ) do |server|
    Rails.application.config.after_initialize do
      server.register_tools(*ApplicationTool.descendants)
    end
  end
elsif Rails.env.production?
  Rails.logger.warn("[FastMcp] MCP_AUTH_TOKEN is not set; MCP server not mounted.")
end
