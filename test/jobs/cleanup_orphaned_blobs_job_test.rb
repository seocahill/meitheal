require "test_helper"

class CleanupOrphanedBlobsJobTest < ActiveJob::TestCase
  test "does not raise ambiguous column error when querying unattached blobs" do
    assert_nothing_raised do
      CleanupOrphanedBlobsJob.perform_now
    end
  end

  test "purges blobs older than one day that are not attached to any record" do
    blob = create_blob("old_orphan.txt")

    travel_to(2.days.from_now) do
      assert_difference "ActiveStorage::Blob.count", -1 do
        CleanupOrphanedBlobsJob.perform_now
      end
    end
  end

  test "does not purge recently created unattached blobs" do
    create_blob("new_orphan.txt")

    assert_no_difference "ActiveStorage::Blob.count" do
      CleanupOrphanedBlobsJob.perform_now
    end
  end

  test "does not purge attached blobs older than one day" do
    profile = profiles(:owner_profile)
    blob = create_blob("attached.txt")
    profile.avatar.attach(blob)

    travel_to(2.days.from_now) do
      assert_no_difference "ActiveStorage::Blob.count" do
        CleanupOrphanedBlobsJob.perform_now
      end
    end
  end

  private

  def create_blob(filename)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("content"),
      filename: filename,
      content_type: "text/plain"
    )
  end
end
