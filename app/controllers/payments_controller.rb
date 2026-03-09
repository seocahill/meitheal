class PaymentsController < ApplicationController
  before_action :set_membership

  def new
    # Simple form for entering amount and description
  end

  def create_checkout
    amount_cents = (params[:amount_euro].to_f * 100).to_i
    description = params[:description].to_s.strip

    if amount_cents <= 0
      return render json: { error: "Amount must be greater than zero" }, status: :unprocessable_entity
    end

    if description.blank?
      return render json: { error: "Description is required" }, status: :unprocessable_entity
    end

    checkout_reference = "payment-#{@membership.id}-#{Time.current.to_i}"

    begin
      checkout = SumupCheckoutService.new.create_checkout(
        amount_cents: amount_cents,
        description: description,
        checkout_reference: checkout_reference,
        return_url: complete_payment_url
      )

      # Store pending payment
      @payment = @membership.payments.create!(
        amount_cents: amount_cents,
        paid_on: Date.current,
        payment_method: :sumup,
        sumup_checkout_id: checkout["id"],
        notes: "Pending - #{description}"
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
    checkout_id = params[:checkout_id]

    if checkout_id.present?
      payment = @membership.payments.find_by(sumup_checkout_id: checkout_id)

      if payment
        begin
          checkout = SumupCheckoutService.new.get_checkout(checkout_id)

          if checkout["status"] == "PAID"
            # Extract description from notes
            description = payment.notes.sub("Pending - ", "")
            payment.update!(
              sumup_transaction_id: checkout["transaction_id"],
              notes: "Completed - #{description}"
            )

            redirect_to my_profile_path, notice: "Payment successful! Thank you."
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
    @membership = Current.user.memberships.first
  end
end
