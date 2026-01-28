class Newsletter < ApplicationRecord
  has_rich_text :content
  belongs_to :chat, optional: true

  validates :subject, presence: true
  validates :content, presence: true

  enum :status, { draft: 0, sent: 1 }, default: :draft

  scope :draft, -> { where(status: :draft) }
  scope :sent, -> { where(status: :sent) }

  def mark_sent!
    update!(status: :sent, sent_at: Time.current)
  end
end
