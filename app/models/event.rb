class Event < ApplicationRecord
  belongs_to :user
  has_many :tickets, dependent: :destroy
  has_one_attached :image
  has_one_attached :qr_code
  has_rich_text :rich_description

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :ticket_url, format: { with: /\Ahttps?:\/\/\S+\z/i, message: "must be a valid http or https URL" }, allow_blank: true

  scope :published, -> { where(published: true) }
  scope :draft, -> { where(published: false) }
  scope :upcoming, -> { where("starts_at > ?", Time.current).order(:starts_at) }

  # The event creator or any editor/owner can edit this event
  def editable_by?(user)
    return false unless user
    self.user == user || user.can_edit?
  end

  # Only editors and owners can publish events
  def publishable_by?(user)
    return false unless user
    user.can_edit?
  end

  def ensure_qr_code(url)
    return unless persisted?
    return if qr_code.attached?

    png = RQRCode::QRCode.new(url).as_png(size: 300)
    qr_code.attach(io: StringIO.new(png.to_s), filename: "qr-code.png", content_type: "image/png")
  end

  def tickets_sold
    tickets.paid.sum(:quantity)
  end

  def tickets_remaining
    return nil unless capacity.present?
    [ capacity - tickets_sold, 0 ].max
  end

  def sold_out?
    return false unless capacity.present?
    tickets_remaining == 0
  end

  def ticketing_available?
    return false unless ticketing_enabled?
    return false unless ticket_price_cents.present? && ticket_price_cents > 0
    return false if sold_out?
    return false if tickets_available_from.present? && tickets_available_from > Time.current
    true
  end

  # Returns the description content - old markdown column if present, otherwise rich text
  def rendered_description
    if description.present?
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      markdown.render(description).html_safe
    elsif rich_description.present?
      # Add target="_blank" and rel="noopener" to all links in ActionText content
      html = rich_description.to_s
      html.gsub(/<a\s+href/, '<a target="_blank" rel="noopener" href').html_safe
    end
  end
end
