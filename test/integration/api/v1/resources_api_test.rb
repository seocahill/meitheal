require "test_helper"

module Api
  module V1
    class ResourcesApiTest < ActionDispatch::IntegrationTest
      TOKEN = ENV["API_TOKEN"]

      def auth_headers(token = TOKEN)
        { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
      end

      # --- Authentication ---------------------------------------------------

      test "rejects requests with no token" do
        get api_v1_faqs_url
        assert_response :unauthorized
      end

      test "rejects requests with a wrong token" do
        get api_v1_faqs_url, headers: auth_headers("nope")
        assert_response :unauthorized
      end

      test "accepts requests with the correct token" do
        get api_v1_faqs_url, headers: auth_headers
        assert_response :success
      end

      # --- Read -------------------------------------------------------------

      test "index returns all records including rich-text fields" do
        get api_v1_faqs_url, headers: auth_headers
        assert_response :success
        body = response.parsed_body
        assert_equal Faq.count, body.size
        assert body.first.key?("answer"), "expected rich-text 'answer' key in serialized faq"
      end

      test "show returns a single record" do
        faq = faqs(:one)
        get api_v1_faq_url(faq), headers: auth_headers
        assert_response :success
        assert_equal faq.id, response.parsed_body["id"]
      end

      test "show returns 404 for a missing record" do
        get api_v1_faq_url(id: 0), headers: auth_headers
        assert_response :not_found
      end

      # --- Create / Update --------------------------------------------------

      test "create persists a valid record" do
        assert_difference -> { Faq.count }, 1 do
          post api_v1_faqs_url,
            params: { faq: { question: "How do I use the API?", answer: "<p>Send a token.</p>", active: true } }.to_json,
            headers: auth_headers
        end
        assert_response :created
        assert_equal "How do I use the API?", response.parsed_body["question"]
      end

      test "create returns 422 with errors for an invalid record" do
        assert_no_difference -> { Faq.count } do
          post api_v1_faqs_url,
            params: { faq: { answer: "<p>no question</p>" } }.to_json,
            headers: auth_headers
        end
        assert_response :unprocessable_entity
        assert_includes response.parsed_body["errors"], "Question can't be blank"
      end

      test "create returns 400 when the body carries no resource params" do
        post api_v1_faqs_url, params: {}.to_json, headers: auth_headers
        assert_response :bad_request
      end

      test "update changes an existing record" do
        faq = faqs(:one)
        patch api_v1_faq_url(faq),
          params: { faq: { question: "Updated question" } }.to_json,
          headers: auth_headers
        assert_response :success
        assert_equal "Updated question", faq.reload.question
      end

      # --- Rich text round-trips as HTML ------------------------------------

      test "rich-text content round-trips as HTML" do
        post api_v1_pages_url,
          params: { page: { title: "API Page", slug: "api-page", locale: "en",
                            visibility: "draft", content: "<p>Hello world</p>" } }.to_json,
          headers: auth_headers
        assert_response :created
        assert_includes response.parsed_body["content"], "Hello world"
      end

      test "flat (unwrapped) body persists rich-text fields" do
        post api_v1_faqs_url,
          params: { question: "Flat body?", answer: "<p>kept</p>", active: true }.to_json,
          headers: auth_headers
        assert_response :created
        assert_includes response.parsed_body["answer"], "kept"
        assert_equal "kept", Faq.find(response.parsed_body["id"]).answer.to_plain_text
      end

      # --- Users are guarded ------------------------------------------------

      test "user role cannot be changed through the API and digest is not exposed" do
        user = users(:editor)
        patch api_v1_user_url(user),
          params: { user: { approved: false, role: "owner" } }.to_json,
          headers: auth_headers
        assert_response :success
        assert_equal "editor", user.reload.role, "role must not be assignable via the API"
        assert_not user.approved?, "permitted attributes should still update"
        assert_not response.parsed_body.key?("password_digest")
      end

      # --- Every resource is reachable --------------------------------------

      RESOURCE_INDEX_PATHS = %w[
        faqs pages posts events newsletters funding_opportunities spaces bookings
        memberships proposals payments tickets email_groups admin_todos profiles users
      ].freeze

      test "every resource index responds successfully" do
        RESOURCE_INDEX_PATHS.each do |resource|
          get "/api/v1/#{resource}", headers: auth_headers
          assert_response :success, "GET /api/v1/#{resource} expected 200 but got #{response.status}"
        end
      end
    end
  end
end
