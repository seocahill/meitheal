class Admin::PaymentsController < Admin::BaseController
  include Pagy::Method
  before_action :require_editor, only: [ :index, :create ]
  before_action :require_owner, only: [ :destroy ]
  before_action :set_membership, except: [ :index ]

  def index
    @date_filter = DateRangeFilter.new(params)
    range = @date_filter.range

    scope = Payment.by_payment_method(known(:payment_method, Payment.payment_methods))
                   .by_purpose(known(:purpose, Payment.purposes))
                   .by_status(known(:status, Payment.statuses))
                   .by_date_range(range&.begin, range&.end)
                   .search(params[:search])

    completed = scope.completed
    @total_cents = completed.sum(:amount_cents)
    @completed_count = completed.count
    @method_totals_cents = completed.group(:payment_method).sum(:amount_cents)

    @pagy, @payments = pagy(scope.includes(membership: { user: :profile }).order(paid_on: :desc, created_at: :desc), limit: 20)
  end

  def create
    user = @membership.user
    @payment = @membership.payments.build(payment_params)
    @payment.user_email = user.email_address
    @payment.user_name = user.name

    if @payment.save
      redirect_to admin_membership_path(@membership), notice: "Payment recorded."
    else
      redirect_to admin_membership_path(@membership), alert: "Could not record payment."
    end
  end

  def destroy
    @payment = @membership.payments.find(params[:id])
    @payment.destroy
    redirect_to admin_membership_path(@membership), notice: "Payment deleted."
  end

  private

  # The param's value when it names one of the enum's values, otherwise nil.
  def known(key, values)
    params[key].presence_in(values.keys)
  end

  def set_membership
    @membership = Membership.find(params[:membership_id])
  end

  def payment_params
    params.require(:payment).permit(:amount_cents, :paid_on, :payment_method, :purpose, :description, :notes)
  end
end
