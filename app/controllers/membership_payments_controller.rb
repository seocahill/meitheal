class MembershipPaymentsController < ApplicationController
  before_action :set_membership

  MEMBERSHIP_PRICES = {
    standard: 5000,   # €50
    concession: 2500  # €25
  }.freeze

  def new
    @amount_cents = MEMBERSHIP_PRICES[@membership.membership_type.to_sym]
  end

  def create_checkout
    amount_cents = MEMBERSHIP_PRICES[@membership.membership_type.to_sym]
    checkout_reference = "membership-#{@membership.id}-#{Time.current.to_i}"

    begin
      checkout = SumupCheckoutService.new.create_checkout(
        amount_cents: amount_cents,
        description: "NCF #{@membership.membership_type.humanize} Membership",
        checkout_reference: checkout_reference,
        return_url: membership_payment_complete_url(@membership)
      )

      # Store pending payment
      @payment = @membership.payments.create!(
        amount_cents: amount_cents,
        paid_on: Date.current,
        payment_method: :sumup,
        sumup_checkout_id: checkout["id"],
        notes: "Pending - checkout created"
      )

      render json: { checkout_id: checkout["id"] }
    rescue SumupCheckoutService::CheckoutError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def complete
    # This is where SumUp redirects after payment
    # We need to verify the checkout status
    checkout_id = params[:checkout_id]

    if checkout_id.present?
      payment = @membership.payments.find_by(sumup_checkout_id: checkout_id)

      if payment
        begin
          checkout = SumupCheckoutService.new.get_checkout(checkout_id)

          if checkout["status"] == "PAID"
            payment.update!(
              sumup_transaction_id: checkout["transaction_id"],
              notes: "Payment completed"
            )

            # Extend membership
            extend_membership!

            redirect_to my_profile_path, notice: "Payment successful! Your membership has been renewed."
          else
            payment.update!(notes: "Payment #{checkout['status']}")
            redirect_to my_profile_path, alert: "Payment was not completed. Status: #{checkout['status']}"
          end
        rescue => e
          Rails.logger.error("SumUp checkout verification failed: #{e.message}")
          redirect_to my_profile_path, alert: "Unable to verify payment. Please contact us if you were charged."
        end
      else
        redirect_to my_profile_path, alert: "Payment not found."
      end
    else
      redirect_to my_profile_path
    end
  end

  private

  def set_membership
    @membership = Current.user.memberships.find(params[:membership_id])
  end

  def extend_membership!
    new_expiry = if @membership.expires_on.present? && @membership.expires_on > Date.current
                   @membership.expires_on + 1.year
                 else
                   1.year.from_now.to_date
                 end

    @membership.update!(expires_on: new_expiry)
  end
end
