require "test_helper"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @membership = memberships(:active_membership)
    sign_in_as(@owner)
  end

  test "should get new payment page" do
    get new_payment_path
    assert_response :success
    assert_match "Make a Payment", response.body
  end

  test "create_checkout returns JSON error when user has no membership" do
    # Delete all memberships for this user so @membership is nil
    @owner.memberships.destroy_all

    post create_checkout_payment_path,
      params: { amount_euro: 20, purpose: "membership", description: "Annual Membership" },
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  test "create_checkout returns JSON error for invalid amount" do
    post create_checkout_payment_path,
      params: { amount_euro: 0, purpose: "membership", description: "Test" },
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "Amount must be greater than zero", json["error"]
  end

  test "create_checkout returns JSON error for missing purpose" do
    post create_checkout_payment_path,
      params: { amount_euro: 20, purpose: "", description: "Test" },
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "Please select a purpose", json["error"]
  end

  test "create_checkout returns JSON error for missing description" do
    post create_checkout_payment_path,
      params: { amount_euro: 20, purpose: "membership", description: "" },
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "Description is required", json["error"]
  end

  test "create_checkout creates payment and returns checkout_id on success" do
    stub_request(:post, SumupCheckoutService::CHECKOUT_URL)
      .to_return(
        status: 200,
        body: { "id" => "test-checkout-123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "Payment.count", 1 do
      post create_checkout_payment_path,
        params: { amount_euro: 20, purpose: "membership", description: "Annual Membership" },
        as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "test-checkout-123", json["checkout_id"]

    payment = Payment.last
    assert_equal 2000, payment.amount_cents
    assert_equal "membership", payment.purpose
    assert_equal "pending", payment.status
    assert_equal "sumup", payment.payment_method
    assert_equal "Annual Membership", payment.description
  end

  test "create_checkout returns JSON error when SumUp service fails" do
    stub_request(:post, SumupCheckoutService::CHECKOUT_URL)
      .to_return(
        status: 400,
        body: { "message" => "Invalid amount" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    post create_checkout_payment_path,
      params: { amount_euro: 20, purpose: "donation", description: "Test donation" },
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "Invalid amount", json["error"]
  end
end
