class CachedEmail < ApplicationRecord
  has_many_attached :attachments

  enum :status, { unread: 0, read: 1, archived: 2 }, default: :unread

  validates :zoho_message_id, presence: true, uniqueness: true
  validates :from_address, presence: true
  validates :subject, presence: true
  validates :received_at, presence: true

  scope :recent, -> { where("received_at >= ?", 30.days.ago).order(received_at: :desc) }
  scope :visible, -> { where.not(status: :archived) }

  # Returns the email body ready for display. Newly synced emails have their inline
  # images replaced with blob paths by SyncZohoEmailsJob. For emails synced before
  # that fix, any remaining Zoho /mail/ImageDisplay references are stripped here to
  # avoid broken image icons (they require web session auth, not our OAuth token).
  def displayable_body
    return body unless body&.include?("ImageDisplay")

    doc = Nokogiri::HTML::DocumentFragment.parse(body)
    doc.css("img[src*='ImageDisplay']").each(&:remove)
    doc.to_html
  end
end
