class Event < ApplicationRecord
  belongs_to :user
  has_one_attached :image
  has_rich_text :rich_description

  validates :title, presence: true
  validates :starts_at, presence: true

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

  # Returns the description content - old markdown column if present, otherwise rich text
  def rendered_description
    if description.present?
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      markdown.render(description).html_safe
    elsif rich_description.present?
      rich_description.to_s.html_safe
    end
  end
end
