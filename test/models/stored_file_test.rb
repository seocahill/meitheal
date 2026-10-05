require "test_helper"

class StoredFileTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionDispatch::TestProcess::FixtureFile

  def pdf
    fixture_file_upload("sample.pdf", "application/pdf")
  end

  test "valid with an attached file and an uploader" do
    stored_file = StoredFile.new(user: users(:editor), file: pdf)
    assert stored_file.valid?
  end

  test "requires a file" do
    stored_file = StoredFile.new(user: users(:editor))
    assert_not stored_file.valid?
    assert_includes stored_file.errors[:file], "can't be blank"
  end

  test "requires an uploader" do
    stored_file = StoredFile.new(file: pdf)
    assert_not stored_file.valid?
    assert_includes stored_file.errors[:user], "must exist"
  end

  test "rejects files over the size limit" do
    stored_file = StoredFile.new(user: users(:editor), file: pdf)
    stored_file.file.blob.byte_size = StoredFile.max_size + 1
    assert_not stored_file.valid?
    assert_match "too large", stored_file.errors[:file].join
    assert_match "2 GB", stored_file.errors[:file].join
  end

  test "filename comes from the attached file" do
    stored_file = StoredFile.create!(user: users(:editor), file: pdf)
    assert_equal "sample.pdf", stored_file.filename
  end

  test "search matches filename and description" do
    by_name = StoredFile.create!(user: users(:editor), file: pdf)
    by_description = StoredFile.create!(user: users(:editor), file: fixture_file_upload("sample.png", "image/png"), description: "AGM minutes")

    assert_includes StoredFile.search("sample.pdf"), by_name
    assert_not_includes StoredFile.search("sample.pdf"), by_description
    assert_includes StoredFile.search("agm"), by_description
    assert_equal StoredFile.count, StoredFile.search("").count
  end

  test "destroying removes the stored blob" do
    stored_file = StoredFile.create!(user: users(:editor), file: pdf)
    blob = stored_file.file.blob
    perform_enqueued_jobs { stored_file.destroy }
    assert_not ActiveStorage::Blob.exists?(blob.id)
  end
end
