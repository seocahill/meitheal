namespace :storage do
  desc "Purge unattached Active Storage blobs older than 2 days. " \
       "Equivalent to the naive query that fails with SQLite's ambiguous column error " \
       "when using a bare created_at in the unattached JOIN."
  task purge_unattached_blobs: :environment do
    count = 0
    ActiveStorage::Blob.unattached
                       .where("active_storage_blobs.created_at <= ?", 2.days.ago)
                       .find_each do |blob|
      blob.purge
      count += 1
    end
    Rails.logger.info("storage:purge_unattached_blobs: purged #{count} blob(s)")
  end
end
