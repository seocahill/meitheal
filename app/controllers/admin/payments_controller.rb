class Admin::PaymentsController < ApplicationController
  include Pagy::Method
  before_action :require_owner
  before_action :set_membership, except: [:index]

  def index
    scope = Payment.includes(:membership).order(paid_on: :desc, created_at: :desc)

    # Apply filters
    scope = scope.by_payment_method(params[:payment_method])
    scope = scope.by_date_range(params[:start_date], params[:end_date])
    scope = scope.search(params[:search])

    @pagy, @payments = pagy(scope, items: 20)
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

  def set_membership
    @membership = Membership.find(params[:membership_id])
  end

  def payment_params
    params.require(:payment).permit(:amount_cents, :paid_on, :payment_method, :description, :notes)
  end
end
