require "test_helper"

class ActiveStorageBlobTest < ActiveSupport::TestCase
  test "unattached_since scope filters by creation time without ambiguous column error" do
    # Reproduces THENCF-T: ActiveStorage::Blob.unattached.where("created_at > ?", ...)
    # fails with SQLite3::SQLException: ambiguous column name: created_at because the
    # unattached scope LEFT JOINs active_storage_attachments which also has created_at.
    count = ActiveStorage::Blob.unattached_since(1.day.ago).count
    assert_kind_of Integer, count
  end
end
