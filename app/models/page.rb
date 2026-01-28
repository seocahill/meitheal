class Page < ApplicationRecord
  has_rich_text :content

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }

  scope :published, -> { where(published: true) }

  def self.find_by_slug(slug)
    find_by!(slug: slug)
  end
end
