class Admin::MembershipsController < Admin::BaseController
  include Pagy::Method

  # Editors look after fees day to day. Changing what a membership is stays with owners.
  before_action :require_editor, only: [ :index, :show, :toggle_paid ]
  before_action :require_owner, except: [ :index, :show, :toggle_paid ]
  before_action :set_membership, only: [ :show, :edit, :update, :destroy, :toggle_paid ]

  OFFLINE_PAYMENT_METHODS = %w[cash bank_transfer other].freeze

  def index
    scope = Membership.includes({ user: :profile }, :payments).joins(:user).left_joins(user: :profile)

    if params[:q].present?
      term = "%#{Membership.sanitize_sql_like(params[:q].downcase)}%"
      scope = scope.where("LOWER(users.email_address) LIKE :term OR LOWER(profiles.name) LIKE :term", term: term)
    end

    scope = case params[:status]
    when "paid"     then scope.paid.order(:expires_on)
    when "lapsed"   then scope.lapsed.order(expires_on: :desc)
    when "unpaid"   then scope.unpaid.order(created_at: :desc)
    when "renewing" then scope.renewing_soon.order(:expires_on)
    when "no_fee"   then scope.no_fee.order(created_at: :desc)
    else scope.order(created_at: :desc)
    end

    @counts = {
      all: Membership.count,
      paid: Membership.paid.count,
      renewing: Membership.renewing_soon.count,
      lapsed: Membership.lapsed.count,
      unpaid: Membership.unpaid.count,
      no_fee: Membership.no_fee.count
    }

    if params[:type].present? && Membership.membership_types.key?(params[:type])
      scope = scope.where(membership_type: params[:type])
    end

    @date_filter = DateRangeFilter.new(params)
    scope = scope.where(expires_on: @date_filter.range) if @date_filter.active?

    @pagy, @memberships = pagy(scope, limit: 20)
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

  # Paid memberships are marked unpaid (to correct a mistake). Unpaid and lapsed
  # ones are marked paid, which records an offline payment and renews for a year.
  def toggle_paid
    if @membership.associate?
      redirect_to admin_memberships_path(list_filters), alert: "Associate memberships have no fee."
    elsif @membership.payment_status == :paid
      @membership.mark_unpaid!
      redirect_to admin_memberships_path(list_filters), notice: "#{member_label} marked unpaid."
    else
      method = params.fetch(:payment_method, "cash")
      unless OFFLINE_PAYMENT_METHODS.include?(method)
        return redirect_to admin_memberships_path(list_filters), alert: "Choose cash, bank transfer or other."
      end

      @membership.record_payment!(payment_method: method)
      redirect_to admin_memberships_path(list_filters), notice: "#{member_label} marked paid until #{@membership.expires_on.strftime('%d %b %Y')}."
    end
  end

  private

  # Keep the current search, filters and page when returning to the list.
  def list_filters
    params.permit(:status, :type, :q, :period, :from, :to, :page).to_h.compact_blank
  end

  def member_label
    @membership.user.name.presence || @membership.user.email_address
  end

  def set_membership
    @membership = Membership.find(params[:id])
  end

  def membership_params
    params.require(:membership).permit(:user_id, :membership_type, :starts_on, :expires_on, :notes)
  end
end
