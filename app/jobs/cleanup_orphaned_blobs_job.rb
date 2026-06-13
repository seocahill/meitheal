class CleanupOrphanedBlobsJob < ApplicationJob
  queue_as :default

  ORPHAN_AGE = 1.day

  def perform
    ActiveStorage::Blob
      .unattached
      .where("active_storage_blobs.created_at < ?", ORPHAN_AGE.ago)
      .find_each(&:purge)
  end
end
