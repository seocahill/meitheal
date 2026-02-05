class Post < ApplicationRecord
  belongs_to :user
  has_rich_text :body
  has_one_attached :featured_image

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }

  enum :post_type, { news: 0, project: 1 }, default: :news

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :draft, -> { where(published_at: nil) }
  scope :recent, -> { order(published_at: :desc) }

  def to_param
    slug
  end

  def published?
    published_at.present? && published_at <= Time.current
  end

  def editable_by?(user)
    return false unless user
    self.user == user || user.can_edit?
  end

  def publishable_by?(user)
    return false unless user
    user.can_edit?
  end

  private

  def generate_slug
    base_slug = title.parameterize
    candidate_slug = base_slug
    counter = 1

    while Post.where(slug: candidate_slug).where.not(id: id).exists?
      candidate_slug = "#{base_slug}-#{counter}"
      counter += 1
    end

    self.slug = candidate_slug
  end
end
