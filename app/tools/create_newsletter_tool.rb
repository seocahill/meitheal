class CreateNewsletterTool < ApplicationTool
  tool_name "create_newsletter"
  description <<~DESC.squish
    Create a draft newsletter. Compose the HTML content yourself from event,
    booking, funding or email information in the database, then call this.
    Use export_newsletter_to_brevo to push it to Brevo afterwards.
  DESC

  arguments do
    required(:subject).filled(:string)
    required(:content).filled(:string).description("Newsletter body as HTML")
  end

  def call(subject:, content:)
    newsletter = Newsletter.create!(subject: subject, content: content)
    "Created draft newsletter ##{newsletter.id}: #{newsletter.subject}"
  rescue ActiveRecord::RecordInvalid => e
    "Could not create newsletter: #{e.record.errors.full_messages.join(', ')}"
  end
end
