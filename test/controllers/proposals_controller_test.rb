require "test_helper"

class ProposalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:viewer)
    @funding_opportunity = funding_opportunities(:arts_council_grant)
  end

  # Unauthenticated users
  test "redirects to login when not authenticated" do
    get new_funding_opportunity_proposal_path(@funding_opportunity)
    assert_redirected_to new_session_path
  end

  # Authenticated member - create proposal
  test "can view new proposal form" do
    sign_in_as @user
    get new_funding_opportunity_proposal_path(@funding_opportunity)
    assert_response :success
  end

  test "can create proposal" do
    sign_in_as @user
    assert_difference "Proposal.count", 1 do
      post funding_opportunity_proposals_path(@funding_opportunity), params: {
        proposal: { title: "My Art Project", description: "A detailed description" }
      }
    end
    assert_redirected_to funding_opportunity_path(@funding_opportunity)
    assert_equal "Proposal saved as draft.", flash[:notice]
  end

  test "can edit own draft proposal" do
    proposal = proposals(:draft)
    sign_in_as users(:owner)  # owner owns the draft fixture
    get edit_funding_opportunity_proposal_path(proposal.funding_opportunity, proposal)
    assert_response :success
  end

  test "can update own draft proposal" do
    proposal = proposals(:draft)
    sign_in_as users(:owner)
    patch funding_opportunity_proposal_path(proposal.funding_opportunity, proposal), params: {
      proposal: { title: "Updated Title" }
    }
    assert_redirected_to funding_opportunity_path(proposal.funding_opportunity)
    assert_equal "Updated Title", proposal.reload.title
  end

  test "cannot edit submitted proposal" do
    proposal = proposals(:submitted)
    sign_in_as users(:editor)  # editor owns the submitted fixture
    get edit_funding_opportunity_proposal_path(proposal.funding_opportunity, proposal)
    assert_redirected_to funding_opportunity_path(proposal.funding_opportunity)
    assert_equal "Cannot edit a submitted proposal.", flash[:alert]
  end

  test "can submit draft proposal" do
    proposal = proposals(:draft)
    sign_in_as users(:owner)
    post submit_funding_opportunity_proposal_path(proposal.funding_opportunity, proposal)
    assert_redirected_to funding_opportunity_path(proposal.funding_opportunity)
    assert proposal.reload.submitted?
  end

  test "cannot edit another users proposal" do
    proposal = proposals(:draft)
    sign_in_as @user  # viewer, not owner
    get edit_funding_opportunity_proposal_path(proposal.funding_opportunity, proposal)
    assert_redirected_to funding_opportunity_path(proposal.funding_opportunity)
    assert_equal "Not authorized.", flash[:alert]
  end

  test "cannot apply to closed opportunity" do
    expired = funding_opportunities(:expired_grant)
    sign_in_as @user
    get new_funding_opportunity_proposal_path(expired)
    assert_redirected_to funding_opportunities_path
    assert_equal "This funding opportunity is closed.", flash[:alert]
  end
end
