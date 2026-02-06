class Booking < ApplicationRecord
  belongs_to :space
  belongs_to :user

  # Virtual attributes for agreement checkboxes
  attr_accessor :agree_booking_rules, :agree_ethics

  validates :title, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate :ends_after_starts
  validate :no_overlapping_bookings
  validate :agreements_accepted, on: :create

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

  def no_overlapping_bookings
    return if starts_at.blank? || ends_at.blank? || space.blank?

    linked_ids = space.linked_space_ids
    return if linked_ids.empty?

    overlapping = Booking.where(space_id: linked_ids)
      .where.not(status: :cancelled)
      .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
    overlapping = overlapping.where.not(id: id) if persisted?

    if overlapping.exists?
      errors.add(:base, "conflicts with an existing booking on a linked space")
    end
  end

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?
    if ends_at <= starts_at
      errors.add(:ends_at, "must be after start time")
    end
  end

  def agreements_accepted
    unless agree_booking_rules.to_s == "1"
      errors.add(:agree_booking_rules, "must be accepted")
    end
    unless agree_ethics.to_s == "1"
      errors.add(:agree_ethics, "must be accepted")
    end
  end
end
