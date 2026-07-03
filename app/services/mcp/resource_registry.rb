module Mcp
  # Maps the MCP-exposed resource names to their models and writable attributes.
  # Writable attributes are read straight from the REST API controllers so the
  # two surfaces can never drift or disagree on what's editable.
  module ResourceRegistry
    module_function

    RESOURCES = %w[
      faqs pages posts events newsletters funding_opportunities spaces bookings
      memberships proposals payments tickets email_groups admin_todos profiles users
    ].freeze

    def resources
      RESOURCES
    end

    def include?(resource)
      RESOURCES.include?(resource.to_s)
    end

    def model_for(resource)
      resource.to_s.classify.constantize
    end

    def writable_attributes(resource)
      controller_for(resource).permitted_attributes.map(&:to_s)
    end

    def controller_for(resource)
      "Api::V1::#{resource.to_s.camelize}Controller".constantize
    end
  end
end
