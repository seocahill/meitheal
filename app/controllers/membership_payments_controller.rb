class MembershipPaymentsController < ApplicationController
  before_action :set_membership

  MEMBERSHIP_PRICES = {
    associate: 0,
    youth: 500,       # €5
    concession: 1000, # €10
    full: 2000        # €20
  }.freeze

  PAID_TYPES = MEMBERSHIP_PRICES.select { |_, v| v > 0 }.keys.freeze

  def new
    @selected_type = @membership.associate? ? :full : @membership.membership_type.to_sym
    @amount_cents = MEMBERSHIP_PRICES[@selected_type]
  end

  def create_checkout
    selected_type = params[:membership_type]&.to_sym
    unless PAID_TYPES.include?(selected_type)
      return render json: { error: "Invalid membership type" }, status: :unprocessable_entity
    end

    membership_fee_cents = MEMBERSHIP_PRICES[selected_type]
    donation_cents = (params[:donation_cents] || 0).to_i
    donation_cents = 0 if donation_cents < 0  # Prevent negative donations
    total_amount_cents = membership_fee_cents + donation_cents

    checkout_reference = "membership-#{@membership.id}-#{Time.current.to_i}"

    user = Current.user
    description = if donation_cents > 0
      "NCF #{selected_type.to_s.humanize} Membership + €#{donation_cents / 100.0} Donation"
    else
      "NCF #{selected_type.to_s.humanize} Membership"
    end

    begin
      checkout = SumupCheckoutService.new.create_checkout(
        amount_cents: total_amount_cents,
        description: description,
        checkout_reference: checkout_reference,
        return_url: complete_membership_payment_url(@membership)
      )

      notes = donation_cents > 0 ? "includes €#{donation_cents / 100.0} donation" : nil
      @payment = @membership.payments.create!(
        amount_cents: total_amount_cents,
        paid_on: Date.current,
        payment_method: :sumup,
        purpose: :membership,
        status: :pending,
        sumup_checkout_id: checkout["id"],
        user_email: user.email_address,
        user_name: user.name,
        description: description,
        notes: notes,
        pending_membership_type: selected_type.to_s
      )

      render json: { checkout_id: checkout["id"] }
    rescue SumupCheckoutService::CheckoutError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error("Payment checkout failed: #{e.class}: #{e.message}")
      render json: { error: "Payment service unavailable. Please try again later." }, status: :service_unavailable
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
              status: :completed,
              sumup_transaction_id: checkout["transaction_id"]
            )

            apply_membership_upgrade!(payment)

            redirect_to my_profile_path, notice: "Payment successful! Your membership has been renewed."
          else
            payment.update!(status: :failed)
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

  def apply_membership_upgrade!(payment)
    new_expiry = if @membership.expires_on.present? && @membership.expires_on > Date.current
                   @membership.expires_on + 1.year
    else
                   1.year.from_now.to_date
    end

    updates = { expires_on: new_expiry }
    updates[:membership_type] = payment.pending_membership_type if payment.pending_membership_type.present?

    @membership.update!(updates)
  end
end
