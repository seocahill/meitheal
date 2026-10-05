# A file an editor uploads to share by link, for example in Notion or on a
# public page. Stored through Active Storage (S3 in production).
class StoredFile < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  validates :file, presence: true
  validate :file_within_size_limit

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :search, ->(term) {
    next all if term.blank?

    pattern = "%#{sanitize_sql_like(term.strip.downcase)}%"
    joins(file_attachment: :blob)
      .where("LOWER(active_storage_blobs.filename) LIKE :p OR LOWER(stored_files.description) LIKE :p", p: pattern)
  }

  def self.max_size
    50.megabytes
  end

  def filename
    file.filename.to_s
  end

  private

  def file_within_size_limit
    return unless file.attached? && file.blob.byte_size > self.class.max_size

    errors.add(:file, "is too large (limit #{ActiveSupport::NumberHelper.number_to_human_size(self.class.max_size)})")
  end
end
