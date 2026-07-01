class ExportNewsletterToBrevoTool < ApplicationTool
  tool_name "export_newsletter_to_brevo"
  description "Export a newsletter to Brevo as a draft campaign, creating or updating it."

  arguments do
    required(:id).filled(:integer).description("The id of the newsletter to export")
  end

  def call(id:)
    newsletter = Newsletter.find_by(id: id)
    return "No newsletter found with id #{id}." if newsletter.nil?

    service = brevo_service
    return "Brevo is not configured; cannot export." unless service.configured?

    if newsletter.brevo_campaign_id.present?
      service.update_campaign(newsletter.brevo_campaign_id, newsletter)
      "Updated newsletter ##{id} in Brevo (campaign #{newsletter.brevo_campaign_id})."
    else
      campaign_id = service.create_campaign(newsletter)
      newsletter.update!(brevo_campaign_id: campaign_id)
      "Exported newsletter ##{id} to Brevo as draft campaign #{campaign_id}."
    end
  rescue BrevoService::ApiError => e
    "Brevo error: #{e.message}"
  end

  private

  def brevo_service
    BrevoService.new
  end
end
