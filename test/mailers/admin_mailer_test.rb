require "test_helper"

class AdminMailerTest < ActionMailer::TestCase
  test "new_funding_opportunity_pending_approval sends to owners" do
    opportunity = funding_opportunities(:pending_grant)
    owner = users(:owner)

    email = AdminMailer.new_funding_opportunity_pending_approval(opportunity)

    assert_equal [ owner.email_address ], email.to
    assert_includes email.subject, opportunity.title
    assert_includes email.body.to_s, opportunity.title
    assert_includes email.body.to_s, opportunity.organization
  end

  test "new_funding_opportunity_pending_approval returns nil with no owners" do
    opportunity = funding_opportunities(:pending_grant)
    User.where(role: :owner).update_all(role: :viewer)

    email = AdminMailer.new_funding_opportunity_pending_approval(opportunity)
    assert_nil email.to
  end
end
