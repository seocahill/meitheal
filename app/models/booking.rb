class Booking < ApplicationRecord
  belongs_to :space
  belongs_to :user

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate :ends_after_starts

  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }, default: :pending

  scope :confirmed, -> { where(status: :confirmed) }
  scope :upcoming, -> { where("starts_at > ?", Time.current).order(:starts_at) }
  scope :for_date, ->(date) {
    where("starts_at >= ? AND starts_at < ?", date.beginning_of_day, date.end_of_day)
  }

  def editable_by?(user)
    return false unless user
    self.user == user || user.can_edit?
  end

  private

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?
    if ends_at <= starts_at
      errors.add(:ends_at, "must be after start time")
    end
  end
end
