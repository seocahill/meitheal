class Page < ApplicationRecord
  has_rich_text :content

  # Nav location determines where the page link appears
  enum :nav_location, { hidden: 0, nav: 1, footer: 2, dropdown: 3 }, default: :hidden

  # Visibility determines who can see the page
  enum :visibility, { draft: 0, published: 1, members_only: 2 }, default: :draft

  LOCALES = %w[en ga].freeze

  validates :title, presence: true
  validates :locale, inclusion: { in: LOCALES }
  validates :slug, presence: true, uniqueness: { scope: :locale }
  validates :slug, format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }
  validate :slug_does_not_clash_with_routes, if: -> { slug.present? && slug_changed? }

  # Nav location scopes
  scope :in_nav, -> { where(nav_location: :nav) }
  scope :in_footer, -> { where(nav_location: :footer) }
  scope :in_dropdown, -> { where(nav_location: :dropdown) }

  # Visibility scopes
  scope :published, -> { where(visibility: :published) }
  scope :visible_to, ->(user) {
    if user.nil?
      where(visibility: :published)
    else
      where(visibility: [ :published, :members_only ])
    end
  }

  def self.find_by_slug(slug)
    find_by!(slug: slug)
  end

  private

  def slug_does_not_clash_with_routes
    route = Rails.application.routes.recognize_path("/#{slug}", method: :get)
    unless route[:controller] == "pages" && route[:action] == "show"
      errors.add(:slug, "is reserved (clashes with an existing route)")
    end
  rescue ActionController::RoutingError
    # No route matches at all — slug is safe to use
  end
end
