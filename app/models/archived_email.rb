class ArchivedEmail < ApplicationRecord
  belongs_to :email_group

  validates :from_address, presence: true
  validates :subject, presence: true
  validates :received_at, presence: true

  scope :recent, -> { where("received_at >= ?", 30.days.ago).order(received_at: :desc) }
end
