class Newsletter < ApplicationRecord
  has_rich_text :content
  belongs_to :chat, optional: true

  validates :subject, presence: true
  validates :content, presence: true

  enum :status, { draft: 0, sent: 1 }, default: :draft

  scope :draft, -> { where(status: :draft) }
  scope :sent, -> { where(status: :sent) }

  def mark_sent!
    update!(status: :sent, sent_at: Time.current)
  end

  def self.build_template
    new(
      subject: "#{Date.current.strftime('%B %Y')} Newsletter",
      content: template_content
    )
  end

  def self.template_content
    sections = []
    sections << "<h2>From the Editors</h2>\n<p>[Editorial content here]</p>"

    events = Event.published.upcoming.limit(5)
    if events.any?
      items = events.map do |e|
        date = e.starts_at.strftime("%A, %B %d at %l:%M%P").squish
        "<li><strong>#{e.title}</strong> — #{date}</li>"
      end
      sections << "<h2>Upcoming Events</h2>\n<ul>\n#{items.join("\n")}\n</ul>"
    end

    opportunities = FundingOpportunity.upcoming.limit(5)
    if opportunities.any?
      items = opportunities.map do |o|
        deadline = o.deadline.strftime("%B %d, %Y")
        "<li><strong>#{o.title}</strong> (#{o.organization}) — Deadline: #{deadline}</li>"
      end
      sections << "<h2>Funding Opportunities</h2>\n<ul>\n#{items.join("\n")}\n</ul>"
    end

    sections << "<h2>News</h2>\n<p>[Generating news section...]</p>"

    sections.join("\n\n")
  end
  private_class_method :template_content
end
