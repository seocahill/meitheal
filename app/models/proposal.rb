class Proposal < ApplicationRecord
  belongs_to :user
  belongs_to :funding_opportunity

  validates :title, presence: true
  validates :user_id, uniqueness: {
    scope: :funding_opportunity_id,
    message: "has already submitted a proposal for this opportunity"
  }

  enum :status, { draft: 0, submitted: 1, approved: 2, rejected: 3 }, default: :draft

  scope :draft, -> { where(status: :draft) }
  scope :submitted, -> { where(status: :submitted) }
  scope :approved, -> { where(status: :approved) }
  scope :rejected, -> { where(status: :rejected) }
  scope :pending_review, -> { submitted }

  def submit!
    raise ActiveRecord::RecordInvalid, self unless draft?
    update!(status: :submitted, submitted_at: Time.current)
  end

  def approve!
    update!(status: :approved, reviewed_at: Time.current)
  end

  def reject!
    update!(status: :rejected, reviewed_at: Time.current)
  end
end
