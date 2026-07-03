module Oauth
  # Publishes the OAuth 2.1 discovery documents Claude fetches before connecting:
  # RFC 8414 authorization-server metadata and RFC 9728 protected-resource metadata.
  class MetadataController < ActionController::Base
    def authorization_server
      render json: {
        issuer: request.base_url,
        authorization_endpoint: oauth_authorization_url,
        token_endpoint: oauth_token_url,
        registration_endpoint: oauth_register_url,
        revocation_endpoint: oauth_revoke_url,
        response_types_supported: %w[code],
        grant_types_supported: %w[authorization_code refresh_token],
        token_endpoint_auth_methods_supported: %w[none],
        code_challenge_methods_supported: %w[S256],
        scopes_supported: %w[mcp:access]
      }
    end

    def protected_resource
      render json: {
        resource: mcp_url,
        authorization_servers: [ request.base_url ],
        bearer_methods_supported: %w[header],
        scopes_supported: %w[mcp:access]
      }
    end
  end
end
