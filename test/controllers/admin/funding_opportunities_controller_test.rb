require "test_helper"

class Admin::FundingOpportunitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @pending = funding_opportunities(:pending_grant)
  end

  # Access control
  test "owner can access funding opportunities index" do
    sign_in_as(@owner)
    get admin_funding_opportunities_path
    assert_response :success
  end

  test "editor cannot access funding opportunities index" do
    sign_in_as(@editor)
    get admin_funding_opportunities_path
    assert_redirected_to root_path
  end

  test "viewer cannot access funding opportunities index" do
    sign_in_as(@viewer)
    get admin_funding_opportunities_path
    assert_redirected_to root_path
  end

  test "unauthenticated user cannot access funding opportunities" do
    get admin_funding_opportunities_path
    assert_redirected_to new_session_path
  end

  # Index shows pending opportunities
  test "index shows pending opportunities" do
    sign_in_as(@owner)
    get admin_funding_opportunities_path
    assert_includes response.body, @pending.title
  end

  test "index does not show approved opportunities" do
    sign_in_as(@owner)
    approved = funding_opportunities(:arts_council_grant)
    get admin_funding_opportunities_path
    assert_not_includes response.body, approved.title
  end

  # Approve action
  test "owner can approve a pending opportunity" do
    sign_in_as(@owner)
    assert_not @pending.approved?

    post approve_admin_funding_opportunity_path(@pending)
    assert_redirected_to admin_funding_opportunities_path

    @pending.reload
    assert @pending.approved?
  end

  test "editor cannot approve a pending opportunity" do
    sign_in_as(@editor)
    post approve_admin_funding_opportunity_path(@pending)
    assert_redirected_to root_path
    @pending.reload
    assert_not @pending.approved?
  end
end
