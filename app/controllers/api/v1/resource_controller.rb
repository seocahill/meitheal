module Api
  module V1
    # Generic read/create/update controller. Each resource subclass declares only
    # its writable attributes via #permitted_attributes; the model and param key
    # are inferred from the controller name by Rails convention (FaqsController →
    # Faq, :faq). Deliberately no #destroy — deletion stays in the admin UI.
    class ResourceController < BaseController
      class_attribute :permitted_attributes, instance_writer: false, default: []

      before_action :set_record, only: [ :show, :update ]

      # Declares the attributes writable through the API and wires parameter
      # wrapping to include them — so a flat JSON body ({"question": ...}) is
      # wrapped correctly, including rich-text fields that aren't DB columns and
      # would otherwise be silently dropped.
      def self.permits(*attributes)
        self.permitted_attributes = attributes
        wrap_parameters controller_name.singularize.to_sym, include: attributes.map(&:to_s)
      end

      def index
        render json: resource_scope.map { |record| serialize(record) }
      end

      def show
        render json: serialize(@record)
      end

      def create
        record = resource_class.new(resource_params)
        if record.save
          render json: serialize(record), status: :created
        else
          render_errors(record)
        end
      end

      def update
        if @record.update(resource_params)
          render json: serialize(@record)
        else
          render_errors(@record)
        end
      end

      private

      def resource_class
        controller_name.classify.constantize
      end

      def resource_scope
        resource_class.all
      end

      def set_record
        @record = resource_scope.find(params[:id])
      end

      def resource_params
        params.require(param_key).permit(*permitted_attributes)
      end

      def param_key
        controller_name.singularize.to_sym
      end

      def render_errors(record)
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end

      def serialize(record)
        Api::RecordSerializer.call(record)
      end
    end
  end
end
