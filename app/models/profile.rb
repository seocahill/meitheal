class Profile < ApplicationRecord
  belongs_to :user
  has_one_attached :avatar
  has_many_attached :portfolio_images

  validates :user_id, uniqueness: true
  validates :name, presence: true
  validates :website, format: { with: /\Ahttps?:\/\/\S+\z/i, message: "must be a valid http or https URL" }, allow_blank: true

  scope :visible, -> { where(visible: true) }
  scope :in_public_gallery, -> { where(public_gallery: true) }
  scope :with_content, -> {
    left_joins(:avatar_attachment).where(
      "active_storage_attachments.id IS NOT NULL " \
      "OR (bio IS NOT NULL AND bio != '') " \
      "OR (skills IS NOT NULL AND skills != '') " \
      "OR (website IS NOT NULL AND website != '') " \
      "OR (location IS NOT NULL AND location != '')"
    ).distinct
  }
  scope :with_skill, ->(skill) { where("skills LIKE ?", "%#{skill}%") }
  scope :search, ->(query) {
    where("profiles.name LIKE ? OR profiles.bio LIKE ?", "%#{query}%", "%#{query}%")
  }

  def skills_list
    return [] if skills.blank?
    skills.split(",").map(&:strip)
  end
end
