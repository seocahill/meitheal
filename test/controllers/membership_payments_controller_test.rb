require "test_helper"

class MembershipPaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @membership = memberships(:active_membership)
    sign_in_as(@owner)
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
end
