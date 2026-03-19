require "test_helper"

class AdminMailerTest < ActionMailer::TestCase
  test "new_funding_opportunity_pending_approval sends to owners" do
    opportunity = funding_opportunities(:pending_grant)
    owner = users(:owner)

    email = AdminMailer.new_funding_opportunity_pending_approval(opportunity)

    assert_equal [ owner.email_address ], email.to
    assert_includes email.subject, opportunity.title
    assert_includes email.body.encoded, opportunity.title
    assert_includes email.body.encoded, opportunity.organization
  end

  test "new_funding_opportunity_pending_approval returns nil with no owners" do
    opportunity = funding_opportunities(:pending_grant)
    User.where(role: :owner).update_all(role: :viewer)

    email = AdminMailer.new_funding_opportunity_pending_approval(opportunity)
    assert_nil email.to
  end

  # daily_pending_summary tests

  test "daily_pending_summary includes all pending item types" do
    # Ensure pending items exist: unapproved user, pending funding opp, submitted proposal
    User.create!(email_address: "unapproved@example.com", password: "password", approved: false)

    email = AdminMailer.daily_pending_summary
    assert_equal [ users(:owner).email_address ], email.to
    assert_equal "Daily summary: items pending your approval", email.subject

    body = email.body.encoded
    assert_includes body, "Users pending approval"
    assert_includes body, "Funding opportunities pending approval"
    assert_includes body, "Proposals pending review"
  end

  test "daily_pending_summary omits sections with zero pending items" do
    # Approve all users and funding opportunities, leave only submitted proposal
    User.where(approved: false).update_all(approved: true)
    FundingOpportunity.pending_approval.update_all(approved: true)

    email = AdminMailer.daily_pending_summary
    body = email.body.encoded
    assert_not_includes body, "Users pending approval"
    assert_not_includes body, "Funding opportunities pending approval"
    assert_includes body, "Proposals pending review"
  end

  test "daily_pending_summary is not sent when nothing is pending" do
    User.where(approved: false).update_all(approved: true)
    FundingOpportunity.pending_approval.update_all(approved: true)
    Proposal.pending_review.update_all(status: :approved)

    email = AdminMailer.daily_pending_summary
    assert_nil email.to
  end

  test "daily_pending_summary is not sent when no owners exist" do
    User.where(role: :owner).update_all(role: :viewer)

    email = AdminMailer.daily_pending_summary
    assert_nil email.to
  end
end
