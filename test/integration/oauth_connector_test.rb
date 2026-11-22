require "test_helper"

# Covers the OAuth 2.1 surface Claude's connector relies on: discovery metadata,
# dynamic client registration, the consent deny path, the PKCE-protected token
# exchange and refresh, and the authorized-applications endpoint.
class OauthConnectorTest < ActionDispatch::IntegrationTest
  test "authorization server metadata advertises the endpoints and S256 PKCE" do
    get "/.well-known/oauth-authorization-server"
    assert_response :success
    body = response.parsed_body
    assert_equal "http://www.example.com", body["issuer"]
    assert_equal "http://www.example.com/oauth/authorize", body["authorization_endpoint"]
    assert_equal "http://www.example.com/oauth/token", body["token_endpoint"]
    assert_equal "http://www.example.com/oauth/register", body["registration_endpoint"]
    assert_equal [ "S256" ], body["code_challenge_methods_supported"]
    assert_includes body["scopes_supported"], "mcp:access"
  end

  test "protected resource metadata points at the MCP endpoint and its auth server" do
    get "/.well-known/oauth-protected-resource"
    assert_response :success
    body = response.parsed_body
    assert_equal "http://www.example.com/mcp", body["resource"]
    assert_equal [ "http://www.example.com" ], body["authorization_servers"]
  end

  test "the /mcp path variant of the metadata is also served" do
    get "/.well-known/oauth-authorization-server/mcp"
    assert_response :success
  end

  test "dynamic client registration creates a public client" do
    assert_difference -> { Doorkeeper::Application.count }, 1 do
      post "/oauth/register", params: {
        client_name: "Claude", redirect_uris: [ "https://claude.ai/api/mcp/auth_callback" ]
      }.to_json, headers: { "Content-Type" => "application/json" }
    end
    assert_response :created
    body = response.parsed_body
    assert body["client_id"].present?
    assert_equal "none", body["token_endpoint_auth_method"]

    app = Doorkeeper::Application.find_by(uid: body["client_id"])
    assert_not app.confidential?, "registered client must be public"
  end

  test "registration without a redirect uri is rejected" do
    post "/oauth/register", params: { client_name: "Claude" }.to_json,
      headers: { "Content-Type" => "application/json" }
    assert_response :bad_request
    assert_equal "invalid_client_metadata", response.parsed_body["error"]
  end

  test "registration with a script-scheme redirect uri is rejected" do
    [ "javascript://claude.ai/%0Aalert(document.domain)", "data://x/text/html" ].each do |uri|
      assert_no_difference -> { Doorkeeper::Application.count }, uri do
        post "/oauth/register", params: { client_name: "Evil", redirect_uris: [ uri ] }.to_json,
          headers: { "Content-Type" => "application/json" }
      end
      assert_response :bad_request
      assert_equal "invalid_client_metadata", response.parsed_body["error"]
    end
  end

  test "denying consent never redirects to a redirect uri the client did not register" do
    app = Doorkeeper::Application.create!(
      name: "Claude", redirect_uri: "https://claude.ai/api/mcp/auth_callback",
      scopes: "mcp:access", confidential: false
    )
    sign_in_as(users(:owner))

    delete "/oauth/authorize", params: {
      client_id: app.uid, redirect_uri: "https://attacker.example/steal",
      response_type: "code", scope: "mcp:access", state: "xyz",
      code_challenge: "a" * 43, code_challenge_method: "S256"
    }

    assert_response :bad_request
    assert_not_includes response.body, "attacker.example"
  end

  test "denying consent redirects to the client's registered uri with access_denied" do
    app = Doorkeeper::Application.create!(
      name: "Claude", redirect_uri: "https://claude.ai/api/mcp/auth_callback",
      scopes: "mcp:access", confidential: false
    )
    sign_in_as(users(:owner))

    delete "/oauth/authorize", params: {
      client_id: app.uid, redirect_uri: app.redirect_uri,
      response_type: "code", scope: "mcp:access", state: "xyz",
      code_challenge: "a" * 43, code_challenge_method: "S256"
    }

    assert_response :redirect
    location = URI(response.location)
    assert_equal "https://claude.ai/api/mcp/auth_callback", "#{location.scheme}://#{location.host}#{location.path}"
    query = Rack::Utils.parse_query(location.query)
    assert_equal "access_denied", query["error"]
    assert_equal "xyz", query["state"]
  end

  test "token endpoint issues a token for a valid PKCE code and rejects a bad verifier" do
    verifier = "a" * 64
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
    app = Doorkeeper::Application.create!(
      name: "Claude", redirect_uri: "https://claude.ai/api/mcp/auth_callback",
      scopes: "mcp:access", confidential: false
    )

    grant = lambda do
      Doorkeeper::AccessGrant.create!(
        application: app, resource_owner_id: users(:owner).id,
        redirect_uri: app.redirect_uri, expires_in: 600, scopes: "mcp:access",
        code_challenge: challenge, code_challenge_method: "S256"
      )
    end

    # Wrong verifier is refused.
    post "/oauth/token", params: {
      grant_type: "authorization_code", code: grant.call.token,
      redirect_uri: app.redirect_uri, client_id: app.uid, code_verifier: "wrong"
    }
    assert_response :bad_request

    # Correct verifier yields an access token scoped to mcp:access.
    post "/oauth/token", params: {
      grant_type: "authorization_code", code: grant.call.token,
      redirect_uri: app.redirect_uri, client_id: app.uid, code_verifier: verifier
    }
    assert_response :success
    assert response.parsed_body["access_token"].present?
    assert_equal "mcp:access", response.parsed_body["scope"]
  end

  test "refresh token yields a new mcp:access token for a public client" do
    app = Doorkeeper::Application.create!(
      name: "Claude", redirect_uri: "https://claude.ai/api/mcp/auth_callback",
      scopes: "mcp:access", confidential: false
    )
    token = Doorkeeper::AccessToken.create!(
      application: app, resource_owner_id: users(:owner).id, scopes: "mcp:access",
      expires_in: 2.hours, use_refresh_token: true
    )

    post "/oauth/token", params: {
      grant_type: "refresh_token", refresh_token: token.refresh_token, client_id: app.uid
    }
    assert_response :success
    assert response.parsed_body["access_token"].present?
    assert_not_equal token.token, response.parsed_body["access_token"]
    assert_equal "mcp:access", response.parsed_body["scope"]
  end

  test "authorized applications require a signed-in owner" do
    get "/oauth/authorized_applications"
    assert_redirected_to new_session_path

    sign_in_as(users(:owner))
    get "/oauth/authorized_applications"
    assert_response :success
  end
end
