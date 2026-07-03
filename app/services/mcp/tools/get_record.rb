module Mcp
  module Tools
    class GetRecord < Base
      tool_name "get_record"
      description "Fetch a single record of a resource by id."
      input_schema(
        properties: {
          resource: {
            type: "string",
            enum: Mcp::ResourceRegistry::RESOURCES,
            description: "Which resource the record belongs to"
          },
          id: { type: "integer", description: "Record id" }
        },
        required: [ "resource", "id" ]
      )

      def self.call(resource:, id:, server_context:)
        return error("Unknown resource: #{resource}") unless registry.include?(resource)

        record = registry.model_for(resource).find_by(id: id)
        return error("#{resource} ##{id} not found") unless record

        json_response(serialize(record))
      end
    end
  end
end
