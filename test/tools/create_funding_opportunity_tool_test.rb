require "test_helper"

class CreateFundingOpportunityToolTest < ActiveSupport::TestCase
  test "creates a pending opportunity attributed to the owner" do
    assert_difference -> { FundingOpportunity.count }, 1 do
      CreateFundingOpportunityTool.new.call(
        title: "New Bursary",
        organization: "Arts Council",
        deadline: "2026-12-01",
        url: "https://example.com/apply",
        amount: 5000,
        description: "A grant for community arts.",
        categories: "arts, community"
      )
    end

    funding = FundingOpportunity.order(:created_at).last
    assert_equal "New Bursary", funding.title
    assert_equal Date.new(2026, 12, 1), funding.deadline
    assert_not funding.approved, "MCP-created opportunities must await approval"
    assert_equal users(:owner), funding.created_by
  end

  test "rejects an unparseable deadline without creating a record" do
    assert_no_difference -> { FundingOpportunity.count } do
      output = CreateFundingOpportunityTool.new.call(
        title: "Bad", organization: "Org", deadline: "not-a-date"
      )
      assert_match(/invalid deadline/i, output)
    end
  end

  test "returns validation errors for an invalid url" do
    output = CreateFundingOpportunityTool.new.call(
      title: "Bad URL", organization: "Org", deadline: "2026-12-01", url: "ftp://nope"
    )
    assert_match(/url/i, output)
  end
end
