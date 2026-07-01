class SearchFundingOpportunitiesTool < ApplicationTool
  tool_name "search_funding_opportunities"
  description "Search existing funding opportunities by text and/or category. Returns matches with their ids."

  arguments do
    optional(:query).filled(:string).description("Text to match against title, organization or description")
    optional(:category).filled(:string).description("Filter to a single category")
  end

  def call(query: nil, category: nil)
    scope = FundingOpportunity.all
    scope = scope.search(query) if query.present?
    scope = scope.by_category(category) if category.present?
    results = scope.order(:deadline).limit(25)

    return "No funding opportunities found." if results.empty?

    results.map { |funding| format_line(funding) }.join("\n")
  end

  private

  def format_line(funding)
    status = funding.approved? ? "approved" : "pending"
    "##{funding.id} [#{status}] #{funding.title} (#{funding.organization}) — deadline #{funding.deadline}"
  end
end
