class ProposalsController < ApplicationController
  before_action :set_funding_opportunity
  before_action :ensure_open, only: [ :new, :create ]
  before_action :set_proposal, only: [ :edit, :update, :submit ]
  before_action :ensure_owner, only: [ :edit, :update, :submit ]
  before_action :ensure_draft, only: [ :edit, :update ]

  def new
    @proposal = @funding_opportunity.proposals.find_or_initialize_by(user: Current.user)
    if @proposal.persisted? && !@proposal.draft?
      redirect_to @funding_opportunity, alert: "You have already submitted a proposal."
    end
  end

  def create
    @proposal = @funding_opportunity.proposals.find_or_initialize_by(user: Current.user)
    @proposal.assign_attributes(proposal_params)

    if @proposal.save
      redirect_to @funding_opportunity, notice: "Proposal saved as draft."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @proposal.update(proposal_params)
      redirect_to @funding_opportunity, notice: "Proposal updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def submit
    unless @proposal.draft?
      redirect_to @funding_opportunity, alert: "Proposal already submitted."
      return
    end

    @proposal.submit!
    redirect_to @funding_opportunity, notice: "Proposal submitted successfully."
  end

  private

  def set_funding_opportunity
    @funding_opportunity = FundingOpportunity.find(params[:funding_opportunity_id])
  end

  def set_proposal
    @proposal = @funding_opportunity.proposals.find(params[:id])
  end

  def ensure_open
    if @funding_opportunity.closed?
      redirect_to funding_opportunities_path, alert: "This funding opportunity is closed."
    end
  end

  def ensure_owner
    unless @proposal.user == Current.user
      redirect_to @funding_opportunity, alert: "Not authorized."
    end
  end

  def ensure_draft
    unless @proposal.draft?
      redirect_to @funding_opportunity, alert: "Cannot edit a submitted proposal."
    end
  end

  def proposal_params
    params.require(:proposal).permit(:title, :description)
  end
end
