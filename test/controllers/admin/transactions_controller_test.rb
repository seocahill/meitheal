require "test_helper"

class Admin::TransactionsControllerTest < ActionDispatch::IntegrationTest
  SAMPLE_RESPONSE = {
    "items" => [
      {
        "id" => "txn-001",
        "transaction_code" => "ABCD1234",
        "amount" => 20.0,
        "currency" => "EUR",
        "timestamp" => "2026-01-15T10:30:00.000Z",
        "status" => "SUCCESSFUL",
        "type" => "PAYMENT",
        "payment_type" => "ECOM"
      },
      {
        "id" => "txn-002",
        "transaction_code" => "EFGH5678",
        "amount" => 10.0,
        "currency" => "EUR",
        "timestamp" => "2026-01-14T09:00:00.000Z",
        "status" => "REFUNDED",
        "type" => "REFUND",
        "payment_type" => "ECOM"
      }
    ],
    "links" => []
  }.freeze

  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
  end

  # Access control — these do not need a real API call
  test "editor cannot access transactions index" do
    sign_in_as(@editor)
    get admin_transactions_path
    assert_redirected_to root_path
  end

  test "viewer cannot access transactions index" do
    sign_in_as(@viewer)
    get admin_transactions_path
    assert_redirected_to root_path
  end

  test "unauthenticated user cannot access transactions" do
    get admin_transactions_path
    assert_redirected_to new_session_path
  end

  # Index behaviour with stubbed service
  test "owner can access transactions index" do
    with_stubbed_service(SAMPLE_RESPONSE) do
      sign_in_as(@owner)
      get admin_transactions_path
      assert_response :success
    end
  end

  test "index displays transaction list" do
    with_stubbed_service(SAMPLE_RESPONSE) do
      sign_in_as(@owner)
      get admin_transactions_path
      assert_response :success
      assert_includes response.body, "ABCD1234"
      assert_includes response.body, "SUCCESSFUL"
      assert_includes response.body, "EFGH5678"
      assert_includes response.body, "REFUNDED"
    end
  end

  test "index shows transaction count" do
    with_stubbed_service(SAMPLE_RESPONSE) do
      sign_in_as(@owner)
      get admin_transactions_path
      assert_includes response.body, "2 transactions"
    end
  end

  test "index shows empty state when no transactions" do
    with_stubbed_service({ "items" => [], "links" => [] }) do
      sign_in_as(@owner)
      get admin_transactions_path
      assert_includes response.body, "No transactions found"
    end
  end

  test "index shows alert when API call fails" do
    error_service = Object.new
    error_service.define_singleton_method(:list_transactions) do |_filters|
      raise SumupCheckoutService::CheckoutError, "API key not configured"
    end

    with_stubbed_service_object(error_service) do
      sign_in_as(@owner)
      get admin_transactions_path
      assert_response :success
      assert_includes response.body, "Could not load transactions"
    end
  end

  test "index passes date filters to service" do
    captured = nil
    capturing_service = Object.new
    capturing_service.define_singleton_method(:list_transactions) do |filters|
      captured = filters
      SAMPLE_RESPONSE
    end

    with_stubbed_service_object(capturing_service) do
      sign_in_as(@owner)
      get admin_transactions_path, params: { from: "2026-01-01", to: "2026-01-31" }
      assert_response :success
    end

    assert_equal "2026-01-01", captured[:oldest_time]
    assert_equal "2026-01-31", captured[:newest_time]
  end

  private

  def with_stubbed_service(response, &block)
    service = Object.new
    service.define_singleton_method(:list_transactions) { |_| response }
    with_stubbed_service_object(service, &block)
  end

  def with_stubbed_service_object(service)
    original = SumupCheckoutService.method(:new)
    SumupCheckoutService.define_singleton_method(:new) { service }
    yield
  ensure
    SumupCheckoutService.define_singleton_method(:new, original)
  end
end
