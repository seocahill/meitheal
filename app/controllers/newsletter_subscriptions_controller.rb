class NewsletterSubscriptionsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 1.hour, only: :create, with: -> {
    redirect_to newsletter_page_path, alert: "Too many attempts. Please try again later."
  }

  def new
    @sent_newsletters = Newsletter.sent.order(sent_at: :desc)
  end

  def qr_code
    svg = RQRCode::QRCode.new(newsletter_page_url).as_svg(module_size: 6, use_path: true, standalone: true)
    send_data svg, type: "image/svg+xml", disposition: "inline", filename: "newsletter-qr.svg"
  end

  def create
    @email = params[:email]&.strip&.downcase

    if @email.blank?
      @sent_newsletters = Newsletter.sent.order(sent_at: :desc)
      flash.now[:alert] = "Please enter your email address."
      return render :new, status: :unprocessable_entity
    end

    if Rails.env.production? && !verify_recaptcha(action: "newsletter_signup", minimum_score: 0.5)
      @sent_newsletters = Newsletter.sent.order(sent_at: :desc)
      flash.now[:alert] = "Verification failed. Please try again."
      return render :new, status: :unprocessable_entity
    end

    subscribe_user(@email)
    sync_to_brevo(@email)

    redirect_to newsletter_page_path, notice: "Thanks for subscribing! You'll receive our next newsletter."
  end

  private

  def subscribe_user(email)
    user = User.find_by(email_address: email)

    if user
      unless user.memberships.active.exists?
        user.memberships.create!(membership_type: :associate, starts_on: Date.current)
      end
    else
      user = User.create!(
        email_address: email,
        password: SecureRandom.hex(32),
        approved: true
      )
      user.create_profile!(name: email.split("@").first)
      user.memberships.create!(membership_type: :associate, starts_on: Date.current)
    end
  end

  def sync_to_brevo(email)
    brevo = BrevoService.new
    brevo.add_contact(email) if brevo.configured?
  rescue BrevoService::ApiError => e
    Rails.logger.warn("Failed to sync newsletter subscriber to Brevo: #{e.message}")
  end
end
