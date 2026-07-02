module Api
  module V1
    # Base for the JSON API. Authenticates every request with a single bearer
    # token (Rails' native HTTP token auth) and renders JSON errors instead of
    # HTML redirects. No cookie session or CSRF — the token is the only credential.
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api_token

      rescue_from ActiveRecord::RecordNotFound do |error|
        render json: { error: error.message }, status: :not_found
      end

      rescue_from ActionController::ParameterMissing do |error|
        render json: { error: error.message }, status: :bad_request
      end

      private

      def authenticate_api_token
        authenticate_or_request_with_http_token do |token, _options|
          expected = self.class.api_token
          expected.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected)
        end
      end

      def self.api_token
        Rails.application.credentials.api_token || ENV["API_TOKEN"]
      end
    end
  end
end
