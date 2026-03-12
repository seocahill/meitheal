class Proposal < ApplicationRecord
  belongs_to :user
  belongs_to :funding_opportunity

  has_many_attached :documents

  validates :title, presence: true
  validates :user_id, uniqueness: {
    scope: :funding_opportunity_id,
    message: "has already submitted a proposal for this opportunity"
  }
  validates :description, presence: true, on: :submit
  validates :submission_deadline, presence: true, on: :submit
  validates :amount_requested, presence: true, numericality: { greater_than: 0 }, on: :submit
  validates :organizer_fee, presence: true, numericality: { greater_than_or_equal_to: 0 }, on: :submit

  enum :status, { draft: 0, submitted: 1, approved: 2, rejected: 3 }, default: :draft

  scope :draft, -> { where(status: :draft) }
  scope :submitted, -> { where(status: :submitted) }
  scope :approved, -> { where(status: :approved) }
  scope :rejected, -> { where(status: :rejected) }
  scope :pending_review, -> { submitted }

  def submit!
    raise ActiveRecord::RecordInvalid, self unless draft?
    raise ActiveRecord::RecordInvalid, self unless valid?(:submit)
    update!(status: :submitted, submitted_at: Time.current)
  end

  def approve!
    update!(status: :approved, reviewed_at: Time.current)
  end

  def reject!
    update!(status: :rejected, reviewed_at: Time.current)
  end
end
