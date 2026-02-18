require "test_helper"

class FundingOpportunityTest < ActiveSupport::TestCase
  test "valid funding opportunity with required attributes" do
    opportunity = FundingOpportunity.new(
      title: "Arts Council Grant",
      organization: "Arts Council Ireland",
      deadline: 2.weeks.from_now
    )
    assert opportunity.valid?
  end

  test "requires title" do
    opportunity = FundingOpportunity.new(organization: "Arts Council", deadline: 1.week.from_now)
    assert_not opportunity.valid?
    assert_includes opportunity.errors[:title], "can't be blank"
  end

  test "requires organization" do
    opportunity = FundingOpportunity.new(title: "Grant", deadline: 1.week.from_now)
    assert_not opportunity.valid?
    assert_includes opportunity.errors[:organization], "can't be blank"
  end

  test "requires deadline" do
    opportunity = FundingOpportunity.new(title: "Grant", organization: "Arts Council")
    assert_not opportunity.valid?
    assert_includes opportunity.errors[:deadline], "can't be blank"
  end

  test "open scope returns opportunities with future deadlines" do
    open_opp = FundingOpportunity.create!(
      title: "Open Grant",
      organization: "Arts Council",
      deadline: 1.week.from_now
    )
    closed_opp = FundingOpportunity.create!(
      title: "Closed Grant",
      organization: "Arts Council",
      deadline: 1.week.ago
    )

    assert_includes FundingOpportunity.open, open_opp
    assert_not_includes FundingOpportunity.open, closed_opp
  end

  test "upcoming scope orders by deadline" do
    later = FundingOpportunity.create!(
      title: "Later Grant",
      organization: "Arts Council",
      deadline: 2.months.from_now,
      approved: true
    )
    sooner = FundingOpportunity.create!(
      title: "Sooner Grant",
      organization: "Arts Council",
      deadline: 1.week.from_now,
      approved: true
    )

    opportunities = FundingOpportunity.upcoming
    assert_equal sooner, opportunities.first
  end

  test "closed? returns true when deadline passed" do
    opportunity = FundingOpportunity.new(deadline: 1.day.ago)
    assert opportunity.closed?
  end

  test "closed? returns false when deadline is future" do
    opportunity = FundingOpportunity.new(deadline: 1.day.from_now)
    assert_not opportunity.closed?
  end

  test "categories_list parses comma separated categories" do
    opportunity = FundingOpportunity.new(categories: "visual art, music, theatre")
    assert_equal [ "visual art", "music", "theatre" ], opportunity.categories_list
  end

  test "categories_list returns empty array when no categories" do
    opportunity = FundingOpportunity.new(categories: nil)
    assert_equal [], opportunity.categories_list
  end

  # Approval scopes
  test "approved scope returns only approved opportunities" do
    approved = funding_opportunities(:arts_council_grant)
    pending = funding_opportunities(:pending_grant)

    assert_includes FundingOpportunity.approved, approved
    assert_not_includes FundingOpportunity.approved, pending
  end

  test "pending_approval scope returns only unapproved opportunities" do
    approved = funding_opportunities(:arts_council_grant)
    pending = funding_opportunities(:pending_grant)

    assert_includes FundingOpportunity.pending_approval, pending
    assert_not_includes FundingOpportunity.pending_approval, approved
  end

  test "upcoming scope only returns approved opportunities" do
    approved = funding_opportunities(:arts_council_grant)
    pending = funding_opportunities(:pending_grant)

    assert_includes FundingOpportunity.upcoming, approved
    assert_not_includes FundingOpportunity.upcoming, pending
  end

  test "approved_or_owned_by returns approved opportunities plus user's pending ones" do
    viewer = users(:viewer)
    approved = funding_opportunities(:arts_council_grant)
    pending = funding_opportunities(:pending_grant) # created_by: viewer

    results = FundingOpportunity.approved_or_owned_by(viewer)
    assert_includes results, approved
    assert_includes results, pending
  end

  test "approved_or_owned_by excludes other users' pending opportunities" do
    editor = users(:editor)
    pending = funding_opportunities(:pending_grant) # created_by: viewer

    results = FundingOpportunity.approved_or_owned_by(editor)
    assert_not_includes results, pending
  end

  test "by_category scope filters by category" do
    visual = FundingOpportunity.create!(
      title: "Visual Grant",
      organization: "Arts Council",
      deadline: 1.week.from_now,
      categories: "visual art, sculpture"
    )
    music = FundingOpportunity.create!(
      title: "Music Grant",
      organization: "Arts Council",
      deadline: 1.week.from_now,
      categories: "music, performance"
    )

    results = FundingOpportunity.by_category("visual")
    assert_includes results, visual
    assert_not_includes results, music
  end
end
