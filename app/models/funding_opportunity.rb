class FundingOpportunity < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  has_many :proposals, dependent: :destroy

  validates :title, presence: true
  validates :organization, presence: true
  validates :deadline, presence: true
  validates :url, format: { with: /\Ahttps?:\/\/\S+\z/i, message: "must be a valid http or https URL" }, allow_blank: true

  def editable_by?(user)
    return false unless user
    user.can_edit? || created_by == user
  end

  scope :open, -> { where("deadline >= ?", Date.current) }
  scope :upcoming, -> { open.order(:deadline) }
  scope :by_category, ->(category) { where("categories LIKE ?", "%#{category}%") }

  def closed?
    deadline < Date.current
  end

  def categories_list
    return [] if categories.blank?
    categories.split(",").map(&:strip)
  end
end
