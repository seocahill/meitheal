require "test_helper"

class SearchFundingOpportunitiesToolTest < ActiveSupport::TestCase
  test "matches by title, organization or description and shows approval status" do
    match = FundingOpportunity.create!(title: "Arts Bursary 2026", organization: "Arts Council",
                                       deadline: 1.month.from_now, approved: true)
    FundingOpportunity.create!(title: "Sports Grant", organization: "Sport Ireland",
                               deadline: 1.month.from_now)

    output = SearchFundingOpportunitiesTool.new.call(query: "bursary")

    assert_match "##{match.id}", output
    assert_match "Arts Bursary 2026", output
    assert_match(/approved/, output)
    assert_no_match(/Sports Grant/, output)
  end

  test "filters by category" do
    music = FundingOpportunity.create!(title: "Music Fund", organization: "Org",
                                       deadline: 1.month.from_now, categories: "music, performance")
    FundingOpportunity.create!(title: "Visual Fund", organization: "Org",
                               deadline: 1.month.from_now, categories: "visual")

    output = SearchFundingOpportunitiesTool.new.call(category: "music")

    assert_match "##{music.id}", output
    assert_no_match(/Visual Fund/, output)
  end

  test "reports when nothing matches" do
    assert_match(/no funding/i, SearchFundingOpportunitiesTool.new.call(query: "nothing"))
  end
end
