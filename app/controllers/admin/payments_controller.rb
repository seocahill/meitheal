class Admin::PaymentsController < ApplicationController
  before_action :require_owner
  before_action :set_membership

  def create
    @payment = @membership.payments.build(payment_params)
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
    params.require(:payment).permit(:amount_cents, :paid_on, :payment_method, :notes)
  end
end
