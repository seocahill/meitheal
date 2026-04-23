class Profile < ApplicationRecord
  belongs_to :user
  has_one_attached :avatar
  has_many_attached :portfolio_images

  validates :user_id, uniqueness: true
  validates :name, presence: true
  validates :website, format: { with: /\Ahttps?:\/\/\S+\z/i, message: "must be a valid http or https URL" }, allow_blank: true

  scope :visible, -> { where(visible: true) }
  scope :in_public_gallery, -> { where(public_gallery: true) }
  scope :with_skill, ->(skill) { where("skills LIKE ?", "%#{skill}%") }
  scope :search, ->(query) {
    where("name LIKE ? OR bio LIKE ?", "%#{query}%", "%#{query}%")
  }

  def skills_list
    return [] if skills.blank?
    skills.split(",").map(&:strip)
  end
end
