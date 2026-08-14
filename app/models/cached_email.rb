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

  # Automated sender prefixes that almost never warrant a follow-up todo
  # (security mailers, transactional notifiers, shipping bots, etc.).
  NOISY_SENDER_PATTERN = /\A(no[-_.]?reply|do[-_.]?not[-_.]?reply|donotreply|notifications?|account[-_.]?security)/i

  # Subject patterns for transactional / automated noise: account security
  # notifications, OTP/verification codes, and delivery status updates.
  NOISY_SUBJECT_PATTERNS = [
    /security alert/i,
    /new (sign[- ]?in|device|login)/i,
    /sign[- ]?in from /i,
    /verify a new (ip|device|location|sign)/i,
    /verification code/i,
    /one[- ]?time (passcode|password|code|pin)/i,
    /(reset your password|password (was )?reset|password reset)/i,
    /(out for delivery|on the way|en route|has shipped|your (package|parcel|order|card) (is|has))/i
  ].freeze

  def noise?
    NOISY_SENDER_PATTERN.match?(from_address.to_s) ||
      NOISY_SUBJECT_PATTERNS.any? { |pattern| pattern.match?(subject.to_s) }
  end

  def to_admin_todo_attrs
    {
      title: "Follow up: #{subject}",
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
end
