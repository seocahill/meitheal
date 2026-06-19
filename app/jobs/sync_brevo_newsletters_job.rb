class SyncBrevoNewslettersJob < ApplicationJob
  queue_as :default

  def perform(brevo_service: BrevoService.new)
    @brevo = brevo_service
    return unless @brevo.configured?

    campaigns = @brevo.sent_campaigns
    Rails.logger.info("SyncBrevoNewslettersJob: Found #{campaigns.size} sent campaigns")

    campaigns.each do |campaign|
      import_campaign(campaign)
    end
  rescue BrevoService::ApiError => e
    Rails.logger.error("SyncBrevoNewslettersJob Brevo error: #{e.message}")
  end

  private

  def import_campaign(campaign)
    campaign_id = campaign[:id]
    campaign_subject = campaign[:subject]

    if Newsletter.exists?(brevo_campaign_id: campaign_id)
      Rails.logger.debug("SyncBrevoNewslettersJob: Skipping #{campaign_subject} (already imported)")
      return
    end

    details = @brevo.campaign_content(campaign_id)
    sent_at = parse_sent_at(details)

    Newsletter.create!(
      subject: details.subject,
      content: BrevoService.strip_email_wrapper(details.html_content),
      status: :sent,
      sent_at: sent_at,
      brevo_campaign_id: campaign_id
    )

    Rails.logger.info("SyncBrevoNewslettersJob: Imported #{details.subject}")
  rescue BrevoService::ApiError, Brevo::ApiError => e
    Rails.logger.warn("SyncBrevoNewslettersJob: Could not import campaign #{campaign_subject}: #{e.message}")
  end

  def parse_sent_at(details)
    Time.parse(details.sent_date)
  rescue ArgumentError, TypeError
    Time.current
  end
end
