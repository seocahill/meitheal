class Admin::ProposalsController < ApplicationController
  before_action :require_owner
  before_action :set_proposal, only: [ :show, :approve, :reject ]

  def index
    @proposals = Proposal.includes(:user, :funding_opportunity).order(created_at: :desc)
    @proposals = @proposals.where(status: params[:status]) if params[:status].present?
  end

  def show
  end

  def approve
    @proposal.approve!
    redirect_to admin_proposals_path, notice: "Proposal approved."
  end

  def reject
    @proposal.admin_notes = params.dig(:proposal, :admin_notes)
    @proposal.reject!
    redirect_to admin_proposals_path, notice: "Proposal rejected."
  end

  private

  def set_proposal
    @proposal = Proposal.find(params[:id])
  end
end
