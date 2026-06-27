class CleanupOrphanedBlobsJob < ApplicationJob
  queue_as :default

  GRACE_PERIOD = 2.days

  def perform
    # Table-qualify created_at to avoid ambiguous column error: the unattached
    # scope does a LEFT JOIN with active_storage_attachments, which also has
    # a created_at column (Sentry THENCF-T).
    ActiveStorage::Blob.unattached
      .where("active_storage_blobs.created_at < ?", GRACE_PERIOD.ago)
      .find_each(&:purge)
  end
end
