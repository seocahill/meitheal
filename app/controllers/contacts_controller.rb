class ContactsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 1.hour, only: :create, with: -> { redirect_to contact_path, alert: "Too many messages. Please try again later." }

  def show
  end

  def create
    @email = params[:email]
    @message = params[:message]

    if Rails.env.production? && !verify_recaptcha(action: "contact", minimum_score: 0.5)
      flash.now[:alert] = "reCAPTCHA verification failed. Please try again."
      return render :show, status: :unprocessable_entity
    end

    if @email.blank? || @message.blank?
      flash.now[:alert] = "Please fill in both fields."
      return render :show, status: :unprocessable_entity
    end

    ContactMailer.contact_message(email: @email, message: @message).deliver_later
    redirect_to contact_path, notice: "Thanks for your message. We'll get back to you soon."
  end
end
