class Admin::MembershipsController < ApplicationController
  before_action :require_owner
  before_action :set_membership, only: [ :show, :edit, :update, :destroy, :mark_as_paid ]

  PER_PAGE = 10

  def index
    scope = Membership.includes(:user, :payments).joins(:user).order(created_at: :desc)

    if params[:q].present?
      scope = scope.where("LOWER(users.email_address) LIKE ?", "%#{params[:q].downcase}%")
    end

    scope = case params[:status]
    when "active"   then scope.active
    when "expired"  then scope.where("expires_on < ?", Date.current)
    else scope
    end

    if params[:type].present? && Membership.membership_types.key?(params[:type])
      scope = scope.where(membership_type: params[:type])
    end

    @page = [ (params[:page] || 1).to_i, 1 ].max
    offset = (@page - 1) * PER_PAGE
    @memberships = scope.offset(offset).limit(PER_PAGE)
    @has_more = scope.count > offset + PER_PAGE
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

  def mark_as_paid
    @membership.update!(membership_type: :full)
    redirect_back fallback_location: admin_memberships_path, notice: "Membership marked as paid (full)."
  end

  private

  def set_membership
    @membership = Membership.find(params[:id])
  end

  def membership_params
    params.require(:membership).permit(:user_id, :membership_type, :starts_on, :expires_on, :notes)
  end
end
