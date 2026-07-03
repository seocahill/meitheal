module Mcp
  # Builds the MCP server exposing the resource tools. `user` is the owner who
  # authorized the connector; it's passed through as server context.
  class Server
    TOOLS = [
      Tools::ListRecords,
      Tools::GetRecord,
      Tools::CreateRecord,
      Tools::UpdateRecord
    ].freeze

    def self.build(user)
      ::MCP::Server.new(
        name: "meitheal",
        title: "Meitheal Admin",
        version: "1.0.0",
        tools: TOOLS,
        server_context: { user: user }
      )
    end
  end
end
