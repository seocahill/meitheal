class FundingOpportunitiesController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]
  before_action :set_funding_opportunity, only: [ :show, :edit, :update, :destroy ]
  before_action :require_editable, only: [ :edit, :update, :destroy ]

  def index
    @funding_opportunities = if authenticated?
      FundingOpportunity.approved_or_owned_by(Current.user).open.order(:deadline)
    else
      FundingOpportunity.upcoming
    end
    if params[:category].present?
      @funding_opportunities = @funding_opportunities.by_category(params[:category])
    end
  end

  def show
    resume_session
    unless @funding_opportunity.approved? || @funding_opportunity.created_by == Current.user || current_user_can_edit?
      redirect_to funding_opportunities_path, alert: "That opportunity is not available."
      return
    end
  end

  def new
    @funding_opportunity = FundingOpportunity.new
  end

  def create
    @funding_opportunity = FundingOpportunity.new(funding_opportunity_params)
    @funding_opportunity.created_by = Current.user
    @funding_opportunity.approved = Current.user.can_edit?
    if @funding_opportunity.save
      notice = if @funding_opportunity.approved?
        "Funding opportunity created."
      else
        "Funding opportunity submitted for approval."
      end
      redirect_to @funding_opportunity, notice: notice
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @funding_opportunity.update(funding_opportunity_params)
      redirect_to @funding_opportunity, notice: "Funding opportunity updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @funding_opportunity.destroy
    redirect_to funding_opportunities_path, notice: "Funding opportunity deleted."
  end

  private

  def set_funding_opportunity
    @funding_opportunity = FundingOpportunity.find(params[:id])
  end

  def funding_opportunity_params
    params.require(:funding_opportunity).permit(:title, :organization, :description, :deadline, :amount, :url, :categories)
  end

  def require_editable
    unless @funding_opportunity.editable_by?(Current.user)
      redirect_to funding_opportunities_path, alert: "You don't have permission to do that."
    end
  end
end
