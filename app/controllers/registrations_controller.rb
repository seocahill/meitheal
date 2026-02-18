class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 5, within: 1.hour, only: :create, with: -> { redirect_to new_registration_path, alert: "Too many registration attempts. Try again later." }

  def new
    @user = User.new
  end

  def create
    if Rails.env.production? && !verify_recaptcha(action: "registration", minimum_score: 0.5)
      @user = User.new(user_params)
      flash.now[:alert] = "reCAPTCHA verification failed. Please try again."
      return render :new, status: :unprocessable_entity
    end

    @user = User.new(user_params)

    if @user.save
      # Create a basic profile
      @user.create_profile(name: params[:user][:name].presence || @user.email_address.split("@").first)

      # Notify admins about pending approval
      AdminMailer.new_user_pending_approval(@user).deliver_later

      redirect_to new_session_path, notice: "Thanks for registering! Your account is pending approval. You'll receive an email once approved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
