class GenerateNewsletterContentJob < ApplicationJob
  queue_as :default

  def perform(newsletter)
    news_html = NewsletterContentService.new.generate_news
    return unless news_html

    current_content = newsletter.content.to_s
    updated_content = current_content.sub(
      /<p>\[Generating news section.*?\]<\/p>/,
      news_html
    )

    newsletter.update!(content: updated_content)

    Turbo::StreamsChannel.broadcast_refresh_to("newsletter_#{newsletter.id}")
  end
end
