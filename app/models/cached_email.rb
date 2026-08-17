class CachedEmail < ApplicationRecord
  has_many_attached :attachments
  has_many :admin_todos, as: :source, dependent: :nullify

  enum :status, { unread: 0, read: 1, archived: 2 }, default: :unread

  validates :zoho_message_id, presence: true, uniqueness: true
  validates :from_address, presence: true
  validates :received_at, presence: true

  scope :recent, -> { where("received_at >= ?", 30.days.ago).order(received_at: :desc) }
  scope :visible, -> { where.not(status: :archived) }
  scope :without_admin_todo, -> {
    where.not(id: AdminTodo.where(source_type: name).select(:source_id))
  }

  # Automated / bulk sender prefixes that almost never warrant a follow-up todo
  # (security mailers, transactional notifiers, shipping bots, newsletters,
  # marketing blasts, and bounce daemons).
  NOISY_SENDER_PATTERN = /\A(no[-_.]?reply|do[-_.]?not[-_.]?reply|donotreply|notifications?|account[-_.]?security|newsletters?|marketing|mailer(?:[-_.]?daemon)?|bounces?|postmaster)/i

  # Subject patterns for transactional / automated noise: account security
  # notifications, OTP/verification codes, delivery status updates, bulk
  # newsletters, auto-replies, and bounce notifications.
  NOISY_SUBJECT_PATTERNS = [
    /security alert/i,
    /new (sign[- ]?in|device|login)/i,
    /sign[- ]?in from /i,
    /verify a new (ip|device|location|sign)/i,
    /verification code/i,
    /one[- ]?time (passcode|password|code|pin)/i,
    /(reset your password|password (was )?reset|password reset)/i,
    /(out for delivery|on the way|en route|has shipped|your (package|parcel|order|card) (is|has))/i,
    /\b(e-?newsletter|newsletter|digest|bulletin)\b/i,
    /(out of office|automatic reply|auto[- ]?reply)/i,
    /(undeliverable|delivery status notification|mail delivery (failed|subsystem)|returned mail)/i
  ].freeze

  # Body markers of bulk mail (newsletters, marketing): a real unsubscribe link
  # or the standard bulk-mail footer. Kept specific enough that a personal email
  # merely mentioning "unsubscribe" in prose is not caught.
  BULK_BODY_PATTERNS = [
    /href=["'][^"']*unsubscribe/i,
    /<a[^>]*>\s*unsubscribe/i,
    /you (are )?receiv(ed|ing) this (e-?mail|message) because/i,
    /view (this )?(e-?mail |message )?in (your )?browser/i,
    /(manage|update) your (e-?mail )?preferences/i
  ].freeze

  def noise?
    automated_sender? || noisy_subject? || bulk_mail?
  end

  def to_admin_todo_attrs
    {
      title: "Follow up: #{subject.presence || '(no subject)'}",
      description: "From: #{from_address}\nReceived: #{received_at.strftime('%B %d, %Y at %I:%M %p')}",
      priority: :normal,
      source: self
    }
  end

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

  private

  def automated_sender?
    NOISY_SENDER_PATTERN.match?(from_address.to_s)
  end

  def noisy_subject?
    NOISY_SUBJECT_PATTERNS.any? { |pattern| pattern.match?(subject.to_s) }
  end

  def bulk_mail?
    return false if body.blank?

    BULK_BODY_PATTERNS.any? { |pattern| pattern.match?(body) }
  end
end
