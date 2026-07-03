require "test_helper"

# Drives the MCP endpoint the way Claude's connector does: JSON-RPC over an
# access-token-protected POST.
class McpEndpointTest < ActionDispatch::IntegrationTest
  def setup
    @oauth_app = Doorkeeper::Application.create!(
      name: "Claude", redirect_uri: "https://claude.ai/api/mcp/auth_callback",
      scopes: "mcp:access", confidential: false
    )
    @token = Doorkeeper::AccessToken.create!(
      application: @oauth_app, resource_owner_id: users(:owner).id,
      scopes: "mcp:access", expires_in: 3600
    ).token
  end

  def rpc(method, params = {}, token: @token)
    headers = { "Content-Type" => "application/json" }
    headers["Authorization"] = "Bearer #{token}" if token
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: method, params: params }.to_json, headers: headers
  end

  # The text payload our tools return is itself JSON — parse it out.
  def tool_json
    JSON.parse(response.parsed_body.dig("result", "content", 0, "text"))
  end

  def tool_error?
    response.parsed_body.dig("result", "isError")
  end

  test "rejects an unauthenticated call with a discovery pointer" do
    post "/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }.to_json,
      headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
    assert_match %r{resource_metadata=".*oauth-protected-resource"}, response.headers["WWW-Authenticate"]
  end

  test "rejects a GET with 405" do
    get "/mcp", headers: { "Authorization" => "Bearer #{@token}" }
    assert_response :method_not_allowed
  end

  test "lists the resource tools" do
    rpc("tools/list")
    assert_response :success
    names = response.parsed_body.dig("result", "tools").map { |t| t["name"] }
    assert_equal %w[create_record get_record list_records update_record], names.sort
  end

  test "list_records returns serialized records" do
    rpc("tools/call", { name: "list_records", arguments: { resource: "faqs" } })
    assert_response :success
    assert_equal Faq.count, tool_json.size
  end

  test "create_record persists a record with rich text" do
    assert_difference -> { Faq.count }, 1 do
      rpc("tools/call", { name: "create_record",
        arguments: { resource: "faqs", attributes: { question: "Via MCP?", answer: "<p>yes</p>", active: true } } })
    end
    assert_response :success
    assert_equal "Via MCP?", tool_json["question"]
    assert_includes tool_json["answer"], "yes"
  end

  test "get_record then update_record round-trips" do
    faq = faqs(:one)
    rpc("tools/call", { name: "get_record", arguments: { resource: "faqs", id: faq.id } })
    assert_equal faq.id, tool_json["id"]

    rpc("tools/call", { name: "update_record",
      arguments: { resource: "faqs", id: faq.id, attributes: { question: "Edited by MCP" } } })
    assert_response :success
    assert_equal "Edited by MCP", faq.reload.question
  end

  test "invalid attributes surface as a tool error" do
    rpc("tools/call", { name: "create_record",
      arguments: { resource: "faqs", attributes: { answer: "<p>no question</p>" } } })
    assert tool_error?
    assert_match "Question can't be blank", response.parsed_body.dig("result", "content", 0, "text")
  end

  test "an unknown resource is rejected" do
    rpc("tools/call", { name: "list_records", arguments: { resource: "sessions" } })
    assert tool_error?
  end

  test "user role cannot be set through the MCP tools" do
    rpc("tools/call", { name: "create_record",
      arguments: { resource: "users", attributes: { email_address: "mcp@example.com", password: "secret123", role: "owner" } } })
    assert_response :success
    created = User.find_by(email_address: "mcp@example.com")
    assert_equal "viewer", created.role, "role must not be assignable via MCP"
    assert_not tool_json.key?("password_digest"), "digest must never be serialized"
  end
end
