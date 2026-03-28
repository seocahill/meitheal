class CachedEmail < ApplicationRecord
  enum :status, { unread: 0, read: 1, archived: 2 }, default: :unread

  validates :zoho_message_id, presence: true, uniqueness: true
  validates :from_address, presence: true
  validates :subject, presence: true
  validates :received_at, presence: true

  scope :recent, -> { where("received_at >= ?", 30.days.ago).order(received_at: :desc) }
  scope :visible, -> { where.not(status: :archived) }
end
