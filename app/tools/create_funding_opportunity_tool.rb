class CreateFundingOpportunityTool < ApplicationTool
  tool_name "create_funding_opportunity"
  description <<~DESC.squish
    Create a funding opportunity (left unapproved for an editor to review).
    Research details from the web yourself, then call this to persist them.
  DESC

  arguments do
    required(:title).filled(:string)
    required(:organization).filled(:string)
    required(:deadline).filled(:string).description("Application deadline as YYYY-MM-DD")
    optional(:url).filled(:string).description("Link to the opportunity")
    optional(:amount).filled(:integer).description("Award amount in euro")
    optional(:description).filled(:string)
    optional(:categories).filled(:string).description("Comma-separated categories")
  end

  def call(title:, organization:, deadline:, url: nil, amount: nil, description: nil, categories: nil)
    parsed_deadline = parse_date(deadline)
    return "Invalid deadline #{deadline.inspect}; use YYYY-MM-DD." if parsed_deadline.nil?

    funding = FundingOpportunity.create!(
      title: title, organization: organization, deadline: parsed_deadline,
      url: url, amount: amount, description: description, categories: categories,
      created_by: owner_user, approved: false
    )
    "Created funding opportunity ##{funding.id}: #{funding.title} (pending approval)."
  rescue ActiveRecord::RecordInvalid => e
    "Could not create funding opportunity: #{e.record.errors.full_messages.join(', ')}"
  end

  private

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
