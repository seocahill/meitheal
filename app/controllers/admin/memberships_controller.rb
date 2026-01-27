class Admin::MembershipsController < ApplicationController
  before_action :require_owner
  before_action :set_membership, only: [ :show, :edit, :update, :destroy ]

  def index
    @memberships = Membership.includes(:user, :payments).order(created_at: :desc)
  end

  def show
  end

  def new
    @membership = Membership.new
    @users = User.order(:email_address)
  end

  def create
    @membership = Membership.new(membership_params)
    if @membership.save
      redirect_to admin_membership_path(@membership), notice: "Membership created."
    else
      @users = User.order(:email_address)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.order(:email_address)
  end

  def update
    if @membership.update(membership_params)
      redirect_to admin_membership_path(@membership), notice: "Membership updated."
    else
      @users = User.order(:email_address)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @membership.destroy
    redirect_to admin_memberships_path, notice: "Membership deleted."
  end

  private

  def set_membership
    @membership = Membership.find(params[:id])
  end

  def membership_params
    params.require(:membership).permit(:user_id, :membership_type, :starts_on, :expires_on, :notes)
  end
end
