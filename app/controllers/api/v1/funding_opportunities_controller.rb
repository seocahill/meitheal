module Api
  module V1
    class FundingOpportunitiesController < ResourceController
      permits :title, :organization, :amount, :categories, :deadline, :description, :url,
              :created_by_id
    end
  end
end
