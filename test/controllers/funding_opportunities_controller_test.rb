require "test_helper"

class FundingOpportunitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @opportunity = funding_opportunities(:arts_council_grant)
  end

  # Public access
  test "index is accessible to public" do
    get funding_opportunities_path
    assert_response :success
  end

  test "index shows opportunities to public" do
    get funding_opportunities_path
    assert_response :success
    assert_includes response.body, @opportunity.title
  end

  test "index shows opportunities to authenticated users" do
    sign_in_as(@viewer)
    get funding_opportunities_path
    assert_includes response.body, @opportunity.title
  end

  test "show is accessible to public" do
    get funding_opportunity_path(@opportunity)
    assert_response :success
    assert_includes response.body, @opportunity.title
  end

  # Any member can create
  test "new requires authentication" do
    get new_funding_opportunity_path
    assert_redirected_to new_session_path
  end

  test "any member can access new form" do
    sign_in_as(@viewer)
    get new_funding_opportunity_path
    assert_response :success
  end

  test "viewer-created opportunity is listed immediately" do
    sign_in_as(@viewer)
    post funding_opportunities_path, params: {
      funding_opportunity: {
        title: "New Grant",
        organization: "Culture Ireland",
        deadline: 1.month.from_now,
        description: "A great opportunity"
      }
    }
    opp = FundingOpportunity.last
    assert_equal @viewer, opp.created_by
    assert_redirected_to funding_opportunity_path(opp)
    assert_equal "Funding opportunity created.", flash[:notice]
    sign_out
    get funding_opportunities_path
    assert_includes response.body, "New Grant"
  end

  # Edit/delete requires editor or creator
  test "editor can edit opportunity" do
    sign_in_as(@editor)
    get edit_funding_opportunity_path(@opportunity)
    assert_response :success
  end

  test "creator can edit their opportunity" do
    # Create opportunity as viewer
    sign_in_as(@viewer)
    post funding_opportunities_path, params: {
      funding_opportunity: {
        title: "My Grant",
        organization: "Local Council",
        deadline: 1.month.from_now
      }
    }
    opp = FundingOpportunity.last

    # Viewer can edit their own
    get edit_funding_opportunity_path(opp)
    assert_response :success
  end

  test "other viewer cannot edit opportunity they didnt create" do
    sign_in_as(@viewer)
    get edit_funding_opportunity_path(@opportunity)
    assert_redirected_to funding_opportunities_path
  end

  test "editor can update opportunity" do
    sign_in_as(@editor)
    patch funding_opportunity_path(@opportunity), params: {
      funding_opportunity: { title: "Updated Title" }
    }
    assert_redirected_to funding_opportunity_path(@opportunity)
    @opportunity.reload
    assert_equal "Updated Title", @opportunity.title
  end

  test "editor can destroy opportunity" do
    sign_in_as(@editor)
    assert_difference "FundingOpportunity.count", -1 do
      delete funding_opportunity_path(@opportunity)
    end
    assert_redirected_to funding_opportunities_path
  end

  # Approved proposals transparency
  test "authenticated member can see approved proposals on show page" do
    sign_in_as(@viewer)
    expired = funding_opportunities(:expired_grant)
    get funding_opportunity_path(expired)
    assert_response :success
    approved = proposals(:approved)
    assert_includes response.body, approved.title
    assert_includes response.body, approved.user.name
  end

  test "public cannot see approved proposals on show page" do
    expired = funding_opportunities(:expired_grant)
    get funding_opportunity_path(expired)
    assert_response :success
    approved = proposals(:approved)
    assert_not_includes response.body, approved.title
  end
end
