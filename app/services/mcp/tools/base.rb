module Mcp
  module Tools
    # Shared helpers for the resource tools. Concrete tools declare their own
    # name/description/input_schema and implement `self.call`.
    class Base < MCP::Tool
      class << self
        private

        def registry
          Mcp::ResourceRegistry
        end

        def json_response(data)
          MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(data) } ])
        end

        def error(message)
          MCP::Tool::Response.new([ { type: "text", text: message } ], error: true)
        end

        def serialize(record)
          Api::RecordSerializer.call(record)
        end

        def writable(resource, attributes)
          (attributes || {}).stringify_keys.slice(*registry.writable_attributes(resource))
        end
      end
    end
  end
end
