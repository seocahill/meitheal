module Mcp
  module Tools
    class CreateRecord < Base
      tool_name "create_record"
      description "Create a record of a resource. `attributes` is an object of field values; " \
                  "unknown or non-writable fields are ignored. Rich-text fields (e.g. answer, " \
                  "content, body) accept HTML. Call get_record or list_records first to learn a " \
                  "resource's fields. Returns the created record or validation errors."
      input_schema(
        properties: {
          resource: {
            type: "string",
            enum: Mcp::ResourceRegistry::RESOURCES,
            description: "Which resource to create"
          },
          attributes: { type: "object", description: "Field values for the new record" }
        },
        required: [ "resource", "attributes" ]
      )

      def self.call(resource:, attributes:, server_context:)
        return error("Unknown resource: #{resource}") unless registry.include?(resource)

        record = registry.model_for(resource).new(writable(resource, attributes))
        if record.save
          json_response(serialize(record))
        else
          error(record.errors.full_messages.join(", "))
        end
      end
    end
  end
end
