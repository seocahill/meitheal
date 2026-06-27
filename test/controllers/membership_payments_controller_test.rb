require "test_helper"

class MembershipPaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @membership = memberships(:active_membership)
    sign_in_as(@owner)
    ENV["SUMUP_API_KEY"] = "test-key"
    ENV["SUMUP_MERCHANT_CODE"] = "test-merchant"
  end

  teardown do
    ENV.delete("SUMUP_API_KEY")
    ENV.delete("SUMUP_MERCHANT_CODE")
  end

  test "should get new payment page" do
    get new_membership_payment_path(@membership)
    assert_response :success
    assert_match "Membership Type", response.body
  end

  test "new page shows membership type options" do
    get new_membership_payment_path(@membership)
    assert_match "Full", response.body
    assert_match "Concession", response.body
    assert_match "Youth", response.body
  end

  test "new page defaults associate members to full" do
    @membership.update!(membership_type: :associate)
    get new_membership_payment_path(@membership)
    assert_select "option[value=full][selected]"
  end

  test "new page selects current paid type" do
    @membership.update!(membership_type: :concession)
    get new_membership_payment_path(@membership)
    assert_select "option[value=concession][selected]"
  end

  # create_checkout

  test "create_checkout does not update membership_type immediately" do
    @membership.update!(membership_type: :associate)

    stub_request(:post, SumupCheckoutService::CHECKOUT_URL)
      .to_return(
        status: 200,
        body: { "id" => "test-checkout-123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    post create_checkout_membership_payment_path(@membership),
      params: { membership_type: "full" },
      as: :json

    assert_response :success
    assert_equal "associate", @membership.reload.membership_type
  end

  test "create_checkout stores pending_membership_type on payment" do
    @membership.update!(membership_type: :associate)

    stub_request(:post, SumupCheckoutService::CHECKOUT_URL)
      .to_return(
        status: 200,
        body: { "id" => "test-checkout-123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "Payment.count", 1 do
      post create_checkout_membership_payment_path(@membership),
        params: { membership_type: "full" },
        as: :json
    end

    assert_equal "full", Payment.last.pending_membership_type
  end

  test "create_checkout returns error for invalid membership type" do
    post create_checkout_membership_payment_path(@membership),
      params: { membership_type: "associate" },
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  # complete

  test "complete with PAID status updates membership_type and extends expiry" do
    original_expiry = @membership.expires_on
    @membership.update!(membership_type: :associate)
    payment = @membership.payments.create!(
      amount_cents: 2000,
      paid_on: Date.current,
      payment_method: :sumup,
      purpose: :membership,
      status: :pending,
      sumup_checkout_id: "test-checkout-paid",
      user_email: @owner.email_address,
      user_name: @owner.name,
      description: "NCF Full Membership",
      pending_membership_type: "full"
    )

    stub_request(:get, "#{SumupCheckoutService::CHECKOUT_URL}/test-checkout-paid")
      .to_return(
        status: 200,
        body: { "status" => "PAID", "transaction_id" => "txn-abc" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get complete_membership_payment_path(@membership, checkout_id: "test-checkout-paid")

    assert_redirected_to my_profile_path
    assert_equal "full", @membership.reload.membership_type
    assert @membership.expires_on > original_expiry
    assert_equal "completed", payment.reload.status
  end

  test "complete with failed payment does not update membership_type" do
    @membership.update!(membership_type: :associate)
    payment = @membership.payments.create!(
      amount_cents: 2000,
      paid_on: Date.current,
      payment_method: :sumup,
      purpose: :membership,
      status: :pending,
      sumup_checkout_id: "test-checkout-failed",
      user_email: @owner.email_address,
      user_name: @owner.name,
      description: "NCF Full Membership",
      pending_membership_type: "full"
    )

    stub_request(:get, "#{SumupCheckoutService::CHECKOUT_URL}/test-checkout-failed")
      .to_return(
        status: 200,
        body: { "status" => "FAILED" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get complete_membership_payment_path(@membership, checkout_id: "test-checkout-failed")

    assert_redirected_to my_profile_path
    assert_equal "associate", @membership.reload.membership_type
    assert_equal "failed", payment.reload.status
  end

  test "complete with PAID status allows retry after previous failed attempt" do
    # Simulates Roisin's scenario: membership was corrupted to :full by a previous
    # failed checkout, then she retries. The new checkout should still work.
    @membership.update!(membership_type: :full)
    payment = @membership.payments.create!(
      amount_cents: 2000,
      paid_on: Date.current,
      payment_method: :sumup,
      purpose: :membership,
      status: :pending,
      sumup_checkout_id: "test-checkout-retry",
      user_email: @owner.email_address,
      user_name: @owner.name,
      description: "NCF Full Membership",
      pending_membership_type: "full"
    )

    stub_request(:get, "#{SumupCheckoutService::CHECKOUT_URL}/test-checkout-retry")
      .to_return(
        status: 200,
        body: { "status" => "PAID", "transaction_id" => "txn-retry" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get complete_membership_payment_path(@membership, checkout_id: "test-checkout-retry")

    assert_redirected_to my_profile_path
    assert_equal "full", @membership.reload.membership_type
    assert_equal "completed", payment.reload.status
  end
end
