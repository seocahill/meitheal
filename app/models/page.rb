class Page < ApplicationRecord
  has_rich_text :content

  # Nav location determines where the page link appears
  enum :nav_location, { hidden: 0, nav: 1, footer: 2, dropdown: 3 }, default: :hidden

  # Visibility determines who can see the page
  enum :visibility, { draft: 0, published: 1, members_only: 2 }, default: :draft

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }

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
end
