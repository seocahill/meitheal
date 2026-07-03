module Mcp
  module Tools
    class UpdateRecord < Base
      tool_name "update_record"
      description "Update an existing record. `attributes` is an object of field values to change; " \
                  "unknown or non-writable fields are ignored. Rich-text fields accept HTML. " \
                  "Returns the updated record or validation errors."
      input_schema(
        properties: {
          resource: {
            type: "string",
            enum: Mcp::ResourceRegistry::RESOURCES,
            description: "Which resource the record belongs to"
          },
          id: { type: "integer", description: "Record id" },
          attributes: { type: "object", description: "Field values to change" }
        },
        required: [ "resource", "id", "attributes" ]
      )

      def self.call(resource:, id:, attributes:, server_context:)
        return error("Unknown resource: #{resource}") unless registry.include?(resource)

        record = registry.model_for(resource).find_by(id: id)
        return error("#{resource} ##{id} not found") unless record

        if record.update(writable(resource, attributes))
          json_response(serialize(record))
        else
          error(record.errors.full_messages.join(", "))
        end
      end
    end
  end
end
