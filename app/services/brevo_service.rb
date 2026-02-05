class BrevoService
  class ApiError < StandardError; end
  class ConfigurationError < ApiError; end

  def initialize
    @api_key = ENV["BREVO_API_KEY"] || Rails.application.credentials.dig(:brevo, :api_key)
    @sender_email = ENV["BREVO_SENDER_EMAIL"] || Rails.application.credentials.dig(:brevo, :sender_email)
    @sender_name = ENV["BREVO_SENDER_NAME"] || Rails.application.credentials.dig(:brevo, :sender_name) || "NCF"
    @list_id = (ENV["BREVO_LIST_ID"] || Rails.application.credentials.dig(:brevo, :list_id))&.to_i
  end

  def configured?
    @api_key.present? && @sender_email.present? && @list_id.present?
  end

  # Create a campaign draft in Brevo
  def create_campaign(newsletter)
    ensure_configured!

    campaign = Brevo::CreateEmailCampaign.new(
      name: campaign_name(newsletter),
      subject: newsletter.subject,
      sender: { email: @sender_email, name: @sender_name },
      html_content: wrap_html_content(newsletter),
      recipients: { list_ids: [ @list_id ] }
    )

    result = campaigns_api.create_email_campaign(campaign)
    result.id
  rescue Brevo::ApiError => e
    Rails.logger.error("Brevo API error: #{e.message}")
    raise ApiError, parse_brevo_error(e)
  end

  # Update an existing campaign draft
  def update_campaign(campaign_id, newsletter)
    ensure_configured!

    campaign = Brevo::UpdateEmailCampaign.new(
      name: campaign_name(newsletter),
      subject: newsletter.subject,
      sender: { email: @sender_email, name: @sender_name },
      html_content: wrap_html_content(newsletter)
    )

    campaigns_api.update_email_campaign(campaign_id, campaign)
    campaign_id
  rescue Brevo::ApiError => e
    Rails.logger.error("Brevo API error: #{e.message}")
    raise ApiError, parse_brevo_error(e)
  end

  # Get campaign status
  def campaign_status(campaign_id)
    ensure_configured!

    result = campaigns_api.get_email_campaign(campaign_id)
    result.status
  rescue Brevo::ApiError => e
    Rails.logger.error("Brevo API error: #{e.message}")
    raise ApiError, parse_brevo_error(e)
  end

  # List available contact lists
  def lists
    ensure_configured!

    result = contacts_api.get_lists
    result.lists || []
  rescue Brevo::ApiError => e
    Rails.logger.error("Brevo API error: #{e.message}")
    raise ApiError, parse_brevo_error(e)
  end

  private

  def ensure_configured!
    return if configured?

    missing = []
    missing << "BREVO_API_KEY" if @api_key.blank?
    missing << "BREVO_SENDER_EMAIL" if @sender_email.blank?
    missing << "BREVO_LIST_ID" if @list_id.blank?
    raise ConfigurationError, "Missing configuration: #{missing.join(', ')}"
  end

  def campaign_name(newsletter)
    "NCF Newsletter: #{newsletter.subject}"[0, 64]
  end

  def wrap_html_content(newsletter)
    content = newsletter.content.to_s

    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px; }
          h1, h2, h3 { color: #1a1a1a; }
          a { color: #7c3aed; }
          img { max-width: 100%; height: auto; }
        </style>
      </head>
      <body>
        #{content}
        <hr style="margin-top: 40px; border: none; border-top: 1px solid #e5e5e5;">
        <p style="font-size: 12px; color: #666;">
          You're receiving this because you're subscribed to NCF newsletters.<br>
          <a href="{{ unsubscribe }}">Unsubscribe</a>
        </p>
      </body>
      </html>
    HTML
  end

  def configure_brevo
    Brevo.configure do |config|
      config.api_key["api-key"] = @api_key
    end
  end

  def campaigns_api
    configure_brevo
    @campaigns_api ||= Brevo::EmailCampaignsApi.new
  end

  def contacts_api
    configure_brevo
    @contacts_api ||= Brevo::ContactsApi.new
  end

  def parse_brevo_error(error)
    body = JSON.parse(error.response_body) rescue {}
    body["message"] || error.message
  end
end
