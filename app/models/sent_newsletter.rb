# Every newsletter that has been sent, for the public newsletter page: the ones
# Brevo has sent (kept up to date automatically) merged with the site's own
# archived copies. Where we hold a copy, the entry points at it, so the archive
# survives changes on the Brevo side. Otherwise it points at Brevo's hosted
# copy.
class SentNewsletter
  Entry = Data.define(:subject, :sent_on, :url, :archive_id)

  CACHE_KEY = "brevo/sent_newsletters"
  CACHE_TTL = 1.hour

  # Brevo being unconfigured or unavailable never breaks the page: the archived
  # copies are listed on their own. Failures are not cached, and the Brevo list
  # is cached so visitors don't each trigger a call. The archive is read each
  # time because it is a cheap local query.
  def self.all(brevo: BrevoService.new, cache: Rails.cache)
    archive = Newsletter.sent.where.not(sent_at: nil).to_a
    merge(brevo_entries(brevo, cache), archive).sort_by(&:sent_on).reverse
  end

  def self.brevo_entries(brevo, cache)
    cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { load_brevo_entries(brevo) }
  rescue BrevoService::ApiError => e
    Rails.logger.warn("Could not load sent newsletters from Brevo: #{e.message}")
    []
  end
  private_class_method :brevo_entries

  def self.load_brevo_entries(brevo)
    brevo.sent_campaigns.filter_map do |campaign|
      url = campaign[:shareLink].presence
      sent = campaign[:sentDate].presence
      next unless url && sent

      { campaign_id: campaign[:id], subject: campaign[:subject], sent_on: Date.parse(sent.to_s), url: url }
    end
  end
  private_class_method :load_brevo_entries

  def self.merge(brevo_entries, archive)
    copies = archive.index_by(&:brevo_campaign_id)
    listed = brevo_entries.map { |entry| entry[:campaign_id] }

    from_brevo = brevo_entries.map do |entry|
      copy = copies[entry[:campaign_id]]
      Entry.new(subject: entry[:subject], sent_on: entry[:sent_on], url: entry[:url], archive_id: copy&.id)
    end
    only_archived = archive.reject { |copy| listed.include?(copy.brevo_campaign_id) }.map do |copy|
      Entry.new(subject: copy.subject, sent_on: copy.sent_at.to_date, url: nil, archive_id: copy.id)
    end

    from_brevo + only_archived
  end
  private_class_method :merge
end
