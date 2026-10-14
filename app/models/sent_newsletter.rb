# Newsletters already sent from Brevo, for the public newsletter page. Each
# links to Brevo's hosted copy. The list is cached so visitors don't each
# trigger a call to Brevo.
class SentNewsletter
  Entry = Data.define(:subject, :sent_on, :url)

  CACHE_KEY = "brevo/sent_newsletters"
  CACHE_TTL = 1.hour

  # Returns an empty list when Brevo is unconfigured or unavailable, so the
  # page it appears on keeps working. Failures are not cached.
  def self.all(brevo: BrevoService.new, cache: Rails.cache)
    cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { load_entries(brevo) }
  rescue BrevoService::ApiError => e
    Rails.logger.warn("Could not load sent newsletters from Brevo: #{e.message}")
    []
  end

  def self.load_entries(brevo)
    brevo.sent_campaigns.filter_map { |campaign| entry_for(campaign) }.sort_by(&:sent_on).reverse
  end
  private_class_method :load_entries

  def self.entry_for(campaign)
    url = campaign[:shareLink].presence
    sent = campaign[:sentDate].presence
    return unless url && sent

    Entry.new(subject: campaign[:subject], sent_on: Date.parse(sent.to_s), url: url)
  end
  private_class_method :entry_for
end
