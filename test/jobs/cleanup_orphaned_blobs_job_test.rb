require "test_helper"

class CleanupOrphanedBlobsJobTest < ActiveJob::TestCase
  test "purges unattached blobs older than 2 days" do
    old_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("old content"),
      filename: "old.txt",
      content_type: "text/plain"
    )
    old_blob.update_column(:created_at, 3.days.ago)

    recent_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("recent content"),
      filename: "recent.txt",
      content_type: "text/plain"
    )

    CleanupOrphanedBlobsJob.perform_now

    assert_raises(ActiveRecord::RecordNotFound) { old_blob.reload }
    assert_nothing_raised { recent_blob.reload }
  end

  test "does not purge attached blobs" do
    proposal = proposals(:draft)

    attached_blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("attached content"),
      filename: "attached.txt",
      content_type: "text/plain"
    )
    attached_blob.update_column(:created_at, 3.days.ago)
    proposal.documents.attach(attached_blob)

    CleanupOrphanedBlobsJob.perform_now

    assert_nothing_raised { attached_blob.reload }
  end

  test "does nothing when there are no orphaned blobs" do
    assert_nothing_raised { CleanupOrphanedBlobsJob.perform_now }
  end
end
