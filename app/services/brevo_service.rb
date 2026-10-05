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

  # Add or update a contact in the configured list
  def add_contact(email, name: nil)
    ensure_configured!

    contact = Brevo::CreateContact.new(
      email: email,
      listIds: [ @list_id ],
      updateEnabled: true,
      attributes: name.present? ? { "FIRSTNAME" => name } : {}
    )

    contacts_api.create_contact(contact)
  rescue Brevo::ApiError => e
    Rails.logger.error("Brevo API error adding contact: #{e.message}")
    raise ApiError, parse_brevo_error(e)
  end

  # List sent campaigns, newest first. Returns hashes with Brevo's own keys
  # (:id, :subject, :sentDate, :shareLink, ...). HTML bodies are left out.
  def sent_campaigns(limit: 50)
    ensure_configured!

    result = campaigns_api.get_email_campaigns(status: "sent", sort: "desc", limit: limit, exclude_html_content: true)
    result.campaigns || []
  rescue Brevo::ApiError => e
    Rails.logger.error("Brevo API error: #{e.message}")
    raise ApiError, parse_brevo_error(e)
  end

  # List available contact lists (only requires API key)
  def lists
    raise ConfigurationError, "Missing configuration: BREVO_API_KEY" if @api_key.blank?

    result = contacts_api.get_lists
    result.lists || []
  rescue Brevo::ApiError => e
    Rails.logger.error("Brevo API error: #{e.message}")
    raise ApiError, parse_brevo_error(e)
  end

  # List all contacts from the configured list
  def list_contacts(limit: 500, offset: 0)
    ensure_configured!

    result = contacts_api.get_contacts_from_list(
      @list_id,
      limit: limit,
      offset: offset
    )
    result.contacts || []
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
