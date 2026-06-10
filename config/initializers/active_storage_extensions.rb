Rails.configuration.to_prepare do
  # Adds unattached_since(time) to ActiveStorage::Blob.
  #
  # The built-in `unattached` scope LEFT JOINs active_storage_attachments, making
  # `created_at` ambiguous in SQLite when a plain WHERE clause references it.
  # This scope qualifies the column so the query works without errors.
  ActiveStorage::Blob.class_eval do
    scope :unattached_since, ->(time) {
      unattached.where("active_storage_blobs.created_at > ?", time)
    }
  end
end
