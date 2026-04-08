module Admin
  class FundingOpportunitiesController < BaseController
    before_action :require_owner
    before_action :set_funding_opportunity, only: [ :approve ]

    def index
      @funding_opportunities = FundingOpportunity.pending_approval.order(:created_at)
    end

    def approve
      @funding_opportunity.update!(approved: true)
      redirect_to admin_funding_opportunities_path, notice: "\"#{@funding_opportunity.title}\" has been approved."
    end

    def refresh
      RefreshFundingOpportunitiesJob.perform_later
      redirect_to admin_funding_opportunities_path, notice: "Funding opportunities refresh started. New opportunities will appear here when complete."
    end

    private

    def set_funding_opportunity
      @funding_opportunity = FundingOpportunity.find(params[:id])
    end
  end
end
