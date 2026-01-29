require "test_helper"

class ProposalTest < ActiveSupport::TestCase
  setup do
    @user = users(:viewer)
    @funding_opportunity = funding_opportunities(:arts_council_grant)
  end

  test "valid proposal" do
    proposal = Proposal.new(
      user: @user,
      funding_opportunity: @funding_opportunity,
      title: "Community Art Installation",
      description: "A proposal for a public art piece"
    )
    assert proposal.valid?
  end

  test "requires user" do
    proposal = Proposal.new(
      funding_opportunity: @funding_opportunity,
      title: "Community Art Installation"
    )
    assert_not proposal.valid?
    assert_includes proposal.errors[:user], "must exist"
  end

  test "requires funding_opportunity" do
    proposal = Proposal.new(
      user: @user,
      title: "Community Art Installation"
    )
    assert_not proposal.valid?
    assert_includes proposal.errors[:funding_opportunity], "must exist"
  end

  test "requires title" do
    proposal = Proposal.new(
      user: @user,
      funding_opportunity: @funding_opportunity
    )
    assert_not proposal.valid?
    assert_includes proposal.errors[:title], "can't be blank"
  end

  test "default status is draft" do
    proposal = Proposal.new(
      user: @user,
      funding_opportunity: @funding_opportunity,
      title: "My Proposal"
    )
    assert_equal "draft", proposal.status
  end

  test "can transition to submitted" do
    proposal = proposals(:draft)
    proposal.submit!
    assert_equal "submitted", proposal.status
    assert_not_nil proposal.submitted_at
  end

  test "can approve submitted proposal" do
    proposal = proposals(:submitted)
    proposal.approve!
    assert_equal "approved", proposal.status
    assert_not_nil proposal.reviewed_at
  end

  test "can reject submitted proposal" do
    proposal = proposals(:submitted)
    proposal.reject!
    assert_equal "rejected", proposal.status
    assert_not_nil proposal.reviewed_at
  end

  test "cannot submit already submitted proposal" do
    proposal = proposals(:submitted)
    assert_raises(ActiveRecord::RecordInvalid) { proposal.submit! }
  end

  test "user can only have one proposal per opportunity" do
    proposal1 = Proposal.create!(
      user: @user,
      funding_opportunity: @funding_opportunity,
      title: "First Proposal"
    )

    proposal2 = Proposal.new(
      user: @user,
      funding_opportunity: @funding_opportunity,
      title: "Second Proposal"
    )
    assert_not proposal2.valid?
    assert_includes proposal2.errors[:user_id], "has already submitted a proposal for this opportunity"
  end

  test "scopes filter by status" do
    assert Proposal.draft.exists?
    assert Proposal.submitted.exists?
  end
end
