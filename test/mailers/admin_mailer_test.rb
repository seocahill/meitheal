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
    # Fixtures provide: pending funding opp, submitted proposal, pending booking, draft event
    User.create!(email_address: "unapproved@example.com", password: "password", approved: false)
    # Create unpaid booking for the summary
    Booking.create!(
      space: spaces(:front_room), user: users(:viewer), title: "Unpaid Booking",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 1.hour,
      status: :confirmed, paid: false,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    email = AdminMailer.daily_pending_summary
    assert_equal [ users(:owner).email_address ], email.to
    assert_equal "Daily summary: items awaiting your action", email.subject

    body = email.body.encoded
    assert_includes body, "Users pending approval"
    assert_includes body, "Funding opportunities pending approval"
    assert_includes body, "Proposals pending review"
    assert_includes body, "Bookings awaiting confirmation"
    assert_includes body, "Events awaiting publication"
    assert_includes body, "Bookings awaiting payment"
  end

  test "daily_pending_summary omits sections with zero pending items" do
    # Clear everything except submitted proposal
    User.where(approved: false).update_all(approved: true)
    FundingOpportunity.pending_approval.update_all(approved: true)
    Booking.pending.update_all(status: :confirmed)
    Booking.confirmed.update_all(paid: true) # Mark all confirmed as paid
    Event.draft.update_all(published: true)

    email = AdminMailer.daily_pending_summary
    body = email.body.encoded
    assert_not_includes body, "Users pending approval"
    assert_not_includes body, "Funding opportunities pending approval"
    assert_not_includes body, "Bookings awaiting confirmation"
    assert_not_includes body, "Bookings awaiting payment"
    assert_not_includes body, "Events awaiting publication"
    assert_includes body, "Proposals pending review"
  end

  test "daily_pending_summary is not sent when nothing needs action" do
    User.where(approved: false).update_all(approved: true)
    FundingOpportunity.pending_approval.update_all(approved: true)
    Proposal.pending_review.update_all(status: :approved)
    Booking.pending.update_all(status: :confirmed)
    Booking.confirmed.update_all(paid: true)
    Event.draft.update_all(published: true)

    email = AdminMailer.daily_pending_summary
    assert_nil email.to
  end

  test "daily_pending_summary is not sent when no owners exist" do
    User.where(role: :owner).update_all(role: :viewer)

    email = AdminMailer.daily_pending_summary
    assert_nil email.to
  end
end
