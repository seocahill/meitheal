module Oauth
  # RFC 7591 Dynamic Client Registration. Claude POSTs its client metadata here
  # and we provision a public (secret-less) Doorkeeper application scoped to
  # mcp:access. Access is granted per-user via PKCE + the authorization flow.
  class RegistrationsController < ActionController::Base
    skip_forgery_protection
    rate_limit to: 10, within: 1.minute, with: :rate_limit_exceeded

    def create
      redirect_uris = Array(params[:redirect_uris]).reject(&:blank?)
      application = Doorkeeper::Application.new(
        name: params[:client_name].presence || "MCP Client",
        redirect_uri: redirect_uris.join("\n"),
        scopes: "mcp:access",
        confidential: false
      )

      if application.save
        render json: {
          client_id: application.uid,
          client_id_issued_at: application.created_at.to_i,
          client_name: application.name,
          redirect_uris: application.redirect_uri.split,
          grant_types: %w[authorization_code refresh_token],
          token_endpoint_auth_method: "none",
          scope: "mcp:access"
        }, status: :created
      else
        render json: {
          error: "invalid_client_metadata",
          error_description: application.errors.full_messages.join(", ")
        }, status: :bad_request
      end
    end

    private

    def rate_limit_exceeded
      render json: { error: "too_many_requests" }, status: :too_many_requests
    end
  end
end
