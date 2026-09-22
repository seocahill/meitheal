class Event < ApplicationRecord
  BOX_OFFICE_CLOSES_BEFORE_START = 30.minutes

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

  # Seats held by editor-added door bookings, which reduce availability
  # without counting as online revenue.
  def tickets_reserved
    tickets.reserved.sum(:quantity)
  end

  def tickets_remaining
    return nil unless capacity.present?
    [ capacity - tickets_sold - tickets_reserved, 0 ].max
  end

  def sold_out?
    return false unless capacity.present?
    tickets_remaining == 0
  end

  def ticket_availability_label
    return nil unless capacity.present?
    return nil if sold_out?
    remaining = tickets_remaining
    if remaining <= (capacity * 0.2).ceil
      "#{remaining} #{remaining == 1 ? "ticket" : "tickets"} left"
    else
      "Tickets still available"
    end
  end

  def ticketing_available?
    return false unless ticketing_enabled?
    return false unless ticket_price_cents.present? && ticket_price_cents > 0
    return false if sold_out?
    return false unless box_office_open?
    return false if tickets_available_from.present? && tickets_available_from > Time.current
    true
  end

  # People currently in the room: everyone checked in, less those who left.
  def audience_count
    [ tickets.admitted.sum(:checked_in_count) - audience_left_count, 0 ].max
  end

  def audience_space_left
    return nil unless capacity.present?
    [ capacity - audience_count, 0 ].max
  end

  def audience_full?
    audience_space_left == 0
  end

  def record_audience_left!
    return if audience_count.zero?
    increment!(:audience_left_count)
  end

  def record_audience_returned!
    return false if audience_left_count.zero? || audience_full?
    decrement!(:audience_left_count)
  end

  def box_office_closes_at
    starts_at - BOX_OFFICE_CLOSES_BEFORE_START
  end

  # Why ticket sales (online and at the door) have stopped, or nil if open.
  def box_office_closed_reason
    if box_office_closed_manually? then :manual
    elsif audience_full? then :full
    elsif Time.current >= box_office_closes_at then :time
    end
  end

  def box_office_open?
    box_office_closed_reason.nil?
  end

  # Paid and reserved tickets for the door list, sorted by name. Matching
  # ignores case and fadas so "siobhan" finds "Siobhán".
  def search_admitted_tickets(query)
    admitted = tickets.admitted.to_a.sort_by { |ticket| searchable(ticket.buyer_name) }
    return admitted if query.blank?

    needle = searchable(query)
    admitted.select do |ticket|
      searchable(ticket.buyer_name).include?(needle) || searchable(ticket.buyer_email).include?(needle)
    end
  end

  # Returns the description content - old markdown column if present, otherwise rich text
  def rendered_description
    if description.present?
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      markdown.render(description).html_safe
    elsif rich_description.present?
      html = YoutubeEmbedTransformer.call(rich_description.to_s)
      html.gsub(/<a\s+href/, '<a target="_blank" rel="noopener" href').html_safe
    end
  end

  private

  def searchable(text)
    I18n.transliterate(text.to_s).downcase.strip
  end
end
