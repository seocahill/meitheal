class FundingOpportunity < ApplicationRecord
  validates :title, presence: true
  validates :organization, presence: true
  validates :deadline, presence: true

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
