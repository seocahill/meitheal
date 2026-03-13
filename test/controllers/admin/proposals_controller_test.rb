require "test_helper"

class Admin::ProposalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @proposal = proposals(:submitted)
  end

  test "non-owners cannot access admin proposals" do
    sign_in_as users(:editor)
    get admin_proposals_path
    assert_redirected_to root_path
  end

  test "owners can view all proposals" do
    sign_in_as @owner
    get admin_proposals_path
    assert_response :success
    assert_select "h1", "Proposals"
  end

  test "owners can filter by status" do
    sign_in_as @owner
    get admin_proposals_path(status: "submitted")
    assert_response :success
  end

  test "owners can view proposal details" do
    sign_in_as @owner
    get admin_proposal_path(@proposal)
    assert_response :success
  end

  test "owners can approve submitted proposal" do
    sign_in_as @owner
    post approve_admin_proposal_path(@proposal)
    assert_redirected_to admin_proposals_path
    assert @proposal.reload.approved?
  end

  test "owners can approve draft proposal" do
    sign_in_as @owner
    draft = proposals(:draft)
    post approve_admin_proposal_path(draft)
    assert_redirected_to admin_proposals_path
    assert draft.reload.approved?
  end

  test "owners can reject proposal with notes" do
    sign_in_as @owner
    post reject_admin_proposal_path(@proposal), params: {
      proposal: { admin_notes: "Budget concerns" }
    }
    assert_redirected_to admin_proposals_path
    assert @proposal.reload.rejected?
    assert_equal "Budget concerns", @proposal.admin_notes
  end

  test "proposal show page displays applicant name" do
    sign_in_as @owner
    get admin_proposal_path(@proposal)
    assert_select "dd", text: @proposal.user.name
  end
end
