class ProposalsController < ApplicationController
  before_action :set_funding_opportunity
  before_action :ensure_open, only: [ :new, :create ]
  before_action :set_proposal, only: [ :edit, :update, :submit ]
  before_action :ensure_owner, only: [ :edit, :update, :submit ]
  before_action :ensure_draft, only: [ :edit, :update ]

  def new
    if current_user_can_edit?
      @proposal = @funding_opportunity.proposals.build
      @users = User.where(approved: true).order(:email_address)
    else
      @proposal = @funding_opportunity.proposals.find_or_initialize_by(user: Current.user)
      if @proposal.persisted? && !@proposal.draft?
        redirect_to @funding_opportunity, alert: "You have already submitted a proposal."
      end
    end
  end

  def create
    if current_user_can_edit?
      @proposal = @funding_opportunity.proposals.build(proposal_params)
      @proposal.user_id ||= Current.user.id
    else
      @proposal = @funding_opportunity.proposals.find_or_initialize_by(user: Current.user)
      @proposal.assign_attributes(proposal_params)
    end

    if @proposal.save
      redirect_to @funding_opportunity, notice: "Proposal saved as draft."
    else
      @users = User.where(approved: true).order(:email_address) if current_user_can_edit?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.where(approved: true).order(:email_address) if current_user_can_edit?
  end

  def update
    if @proposal.update(proposal_params)
      redirect_to @funding_opportunity, notice: "Proposal updated."
    else
      @users = User.where(approved: true).order(:email_address) if current_user_can_edit?
      render :edit, status: :unprocessable_entity
    end
  end

  def submit
    unless @proposal.draft?
      redirect_to @funding_opportunity, alert: "Proposal already submitted."
      return
    end

    if @proposal.valid?(:submit)
      @proposal.submit!
      redirect_to @funding_opportunity, notice: "Proposal submitted successfully."
    else
      flash.now[:alert] = "Please fill in all required fields before submitting."
      @users = User.where(approved: true).order(:email_address) if current_user_can_edit?
      render :edit, status: :unprocessable_entity
    end
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
    return if current_user_can_edit?
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
    permitted = [ :title, :description, :submission_deadline, :amount_requested, :organizer_fee, documents: [] ]
    permitted << :user_id if current_user_can_edit?
    params.require(:proposal).permit(permitted)
  end
end
