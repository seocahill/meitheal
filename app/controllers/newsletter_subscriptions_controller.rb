# The public newsletter page, open to anyone (member or not): sign up, the QR
# code for the signup page, and the past issues. Signing up goes straight to
# the Brevo mailing list; nothing is created on the platform.
class NewsletterSubscriptionsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 1.hour, only: :create, with: -> {
    redirect_to newsletter_page_path, alert: "Too many attempts. Please try again later."
  }

  helper_method :sent_newsletters

  def new
  end

  def qr_code
    svg = RQRCode::QRCode.new(newsletter_page_url).as_svg(module_size: 6, use_path: true, standalone: true)
    send_data svg, type: "image/svg+xml", disposition: "inline", filename: "newsletter-qr.svg"
  end

  def create
    @email = params[:email].to_s.strip.downcase

    if @email.blank?
      return reject("Please enter your email address.")
    elsif !@email.match?(URI::MailTo::EMAIL_REGEXP)
      return reject("That doesn't look like an email address.")
    elsif Rails.env.production? && !verify_recaptcha(action: "newsletter_signup", minimum_score: 0.5)
      return reject("Verification failed. Please try again.")
    end

    BrevoService.new.add_contact(@email)
    redirect_to newsletter_page_path, notice: "Thanks for subscribing! You'll receive our next newsletter."
  rescue BrevoService::ApiError => e
    Rails.logger.warn("Newsletter signup failed in Brevo: #{e.message}")
    reject("Sorry, we couldn't sign you up just now. Please try again later.")
  end

  private

  # Read lazily so a failed signup re-render and a normal visit both get the
  # list, and a successful signup never calls Brevo for it.
  def sent_newsletters
    @sent_newsletters ||= SentNewsletter.all
  end

  def reject(message)
    flash.now[:alert] = message
    render :new, status: :unprocessable_entity
  end
end
