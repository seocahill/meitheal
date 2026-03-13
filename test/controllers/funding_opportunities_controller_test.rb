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

  test "index shows approved opportunities to public" do
    get funding_opportunities_path
    assert_response :success
    assert_includes response.body, @opportunity.title
  end

  test "index does not show pending opportunities to public" do
    pending = funding_opportunities(:pending_grant)
    get funding_opportunities_path
    assert_not_includes response.body, pending.title
  end

  test "index shows approved opportunities to authenticated users" do
    sign_in_as(@viewer)
    get funding_opportunities_path
    assert_includes response.body, @opportunity.title
  end

  test "index shows own pending opportunities to creator" do
    sign_in_as(@viewer)
    get funding_opportunities_path
    pending = funding_opportunities(:pending_grant)
    assert_includes response.body, pending.title
  end

  test "index does not show other users pending opportunities" do
    sign_in_as(@editor)
    get funding_opportunities_path
    pending = funding_opportunities(:pending_grant)
    assert_not_includes response.body, pending.title
  end

  test "show is accessible to public for approved opportunities" do
    get funding_opportunity_path(@opportunity)
    assert_response :success
    assert_includes response.body, @opportunity.title
  end

  test "show redirects public from pending opportunities" do
    pending = funding_opportunities(:pending_grant)
    get funding_opportunity_path(pending)
    assert_redirected_to funding_opportunities_path
  end

  test "show allows creator to view their pending opportunity" do
    sign_in_as(@viewer)
    pending = funding_opportunities(:pending_grant)
    get funding_opportunity_path(pending)
    assert_response :success
  end

  test "show allows editor to view pending opportunity" do
    sign_in_as(@editor)
    pending = funding_opportunities(:pending_grant)
    get funding_opportunity_path(pending)
    assert_response :success
  end

  test "show redirects other members from pending opportunity" do
    other_viewer = User.create!(email_address: "other@example.com", password: "password", approved: true)
    sign_in_as(other_viewer)
    pending = funding_opportunities(:pending_grant)
    get funding_opportunity_path(pending)
    assert_redirected_to funding_opportunities_path
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

  test "viewer-created opportunity is pending approval" do
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
    assert_not opp.approved?
    assert_equal "Funding opportunity submitted for approval.", flash[:notice]
  end

  test "editor-created opportunity is auto-approved" do
    sign_in_as(@editor)
    post funding_opportunities_path, params: {
      funding_opportunity: {
        title: "Editor Grant",
        organization: "Culture Ireland",
        deadline: 1.month.from_now,
        description: "An editor opportunity"
      }
    }
    opp = FundingOpportunity.last
    assert opp.approved?
    assert_equal "Funding opportunity created.", flash[:notice]
  end

  test "viewer-created opportunity sends admin notification" do
    sign_in_as(@viewer)
    assert_enqueued_emails(1) do
      post funding_opportunities_path, params: {
        funding_opportunity: {
          title: "Notification Grant",
          organization: "Test Org",
          deadline: 1.month.from_now
        }
      }
    end
  end

  test "editor-created opportunity does not send admin notification" do
    sign_in_as(@editor)
    assert_no_enqueued_emails do
      post funding_opportunities_path, params: {
        funding_opportunity: {
          title: "Editor Grant No Email",
          organization: "Test Org",
          deadline: 1.month.from_now
        }
      }
    end
  end

  test "owner-created opportunity is auto-approved" do
    sign_in_as(@owner)
    post funding_opportunities_path, params: {
      funding_opportunity: {
        title: "Owner Grant",
        organization: "Culture Ireland",
        deadline: 1.month.from_now
      }
    }
    assert FundingOpportunity.last.approved?
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
