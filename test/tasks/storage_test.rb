require "test_helper"

class StorageTasksTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks
  end

  # Reproduces THENCF-T: bare "created_at" is ambiguous when the unattached scope
  # does a LEFT OUTER JOIN between active_storage_blobs and active_storage_attachments,
  # because both tables have a created_at column.
  test "querying unattached blobs with bare created_at raises ambiguous column error" do
    error = assert_raises(ActiveRecord::StatementInvalid) do
      ActiveStorage::Blob.unattached.where("created_at > ?", 1.day.ago).load
    end
    assert_match(/ambiguous column name: created_at/i, error.message)
  end

  test "storage:purge_unattached_blobs task removes orphaned blobs older than 2 days" do
    blob = travel_to(3.days.ago) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("orphaned content"),
        filename: "orphan.txt",
        content_type: "text/plain"
      )
    end

    assert ActiveStorage::Blob.exists?(blob.id), "blob should exist before purge"

    Rake::Task["storage:purge_unattached_blobs"].reenable
    Rake::Task["storage:purge_unattached_blobs"].invoke

    assert_not ActiveStorage::Blob.exists?(blob.id), "orphaned blob should be purged"
  end

  test "storage:purge_unattached_blobs task does not remove recent unattached blobs" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("recent orphan"),
      filename: "recent.txt",
      content_type: "text/plain"
    )

    Rake::Task["storage:purge_unattached_blobs"].reenable
    Rake::Task["storage:purge_unattached_blobs"].invoke

    assert ActiveStorage::Blob.exists?(blob.id), "recent unattached blob should not be purged"
  end

  test "storage:purge_unattached_blobs task does not remove attached blobs" do
    cached_email = CachedEmail.create!(
      zoho_message_id: "test-msg-#{SecureRandom.hex(8)}",
      zoho_folder_id: "folder-1",
      from_address: "sender@example.com",
      subject: "Test email",
      received_at: Time.current
    )

    blob = travel_to(3.days.ago) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("attached content"),
        filename: "attachment.txt",
        content_type: "text/plain"
      )
    end
    cached_email.attachments.attach(blob)

    Rake::Task["storage:purge_unattached_blobs"].reenable
    Rake::Task["storage:purge_unattached_blobs"].invoke

    assert ActiveStorage::Blob.exists?(blob.id), "attached blob should not be purged"
  end
end
