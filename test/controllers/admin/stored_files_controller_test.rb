require "test_helper"

class Admin::StoredFilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = users(:editor)
    @viewer = users(:viewer)
  end

  def upload(name = "sample.pdf", type = "application/pdf")
    fixture_file_upload(name, type)
  end

  def with_max_size(bytes)
    StoredFile.singleton_class.alias_method :original_max_size, :max_size
    StoredFile.define_singleton_method(:max_size) { bytes }
    yield
  ensure
    StoredFile.singleton_class.alias_method :max_size, :original_max_size
    StoredFile.singleton_class.remove_method :original_max_size
  end

  # Access control
  test "viewers cannot see the file list" do
    sign_in_as(@viewer)
    get admin_stored_files_path
    assert_redirected_to root_path
  end

  test "signed-out visitors are sent to sign in" do
    get admin_stored_files_path
    assert_redirected_to new_session_path
  end

  test "viewers cannot upload" do
    sign_in_as(@viewer)
    assert_no_difference "StoredFile.count" do
      post admin_stored_files_path, params: { stored_file: { files: [ upload ] } }
    end
    assert_redirected_to root_path
  end

  test "viewers cannot delete" do
    stored_file = StoredFile.create!(user: @editor, file: upload)
    sign_in_as(@viewer)
    assert_no_difference "StoredFile.count" do
      delete admin_stored_file_path(stored_file)
    end
  end

  # Listing
  test "editor sees the upload form and an empty state" do
    sign_in_as(@editor)
    get admin_stored_files_path
    assert_response :success
    assert_select "form[enctype='multipart/form-data']"
    assert_includes response.body, "No files yet"
  end

  test "list shows filename, uploader and a shareable link that works without signing in" do
    stored_file = StoredFile.create!(user: @editor, file: upload, description: "Fire safety plan")
    sign_in_as(@editor)
    get admin_stored_files_path
    assert_includes response.body, "sample.pdf"
    assert_includes response.body, "Fire safety plan"
    assert_includes response.body, @editor.email_address

    link = css_select("input[data-clipboard-target='source']").first["value"]
    assert_equal rails_blob_url(stored_file.file), link

    sign_out
    get link
    assert_response :redirect
  end

  test "list is newest first" do
    StoredFile.create!(user: @editor, file: upload, description: "older one", created_at: 2.days.ago)
    StoredFile.create!(user: @editor, file: upload("sample.png", "image/png"), description: "newer one")
    sign_in_as(@editor)
    get admin_stored_files_path
    assert_operator response.body.index("newer one"), :<, response.body.index("older one")
  end

  test "search narrows the list" do
    StoredFile.create!(user: @editor, file: upload, description: "AGM minutes")
    StoredFile.create!(user: @editor, file: upload("sample.png", "image/png"), description: "Logo")
    sign_in_as(@editor)
    get admin_stored_files_path(q: "agm")
    assert_includes response.body, "AGM minutes"
    assert_not_includes response.body, "Logo"
  end

  # Uploading
  test "editor uploads a file" do
    sign_in_as(@editor)
    assert_difference "StoredFile.count", 1 do
      post admin_stored_files_path, params: { stored_file: { files: [ upload ], description: "Constitution" } }
    end
    stored_file = StoredFile.last
    assert_equal @editor, stored_file.user
    assert_equal "Constitution", stored_file.description
    assert stored_file.file.attached?
    assert_redirected_to admin_stored_files_path
    assert_match "sample.pdf", flash[:notice]
  end

  test "several files can be uploaded at once" do
    sign_in_as(@editor)
    assert_difference "StoredFile.count", 2 do
      post admin_stored_files_path, params: { stored_file: { files: [ upload, upload("sample.png", "image/png") ] } }
    end
    assert_equal [ "sample.pdf", "sample.png" ], StoredFile.order(:id).last(2).map(&:filename)
  end

  test "uploading with no file chosen explains what to do" do
    sign_in_as(@editor)
    assert_no_difference "StoredFile.count" do
      post admin_stored_files_path, params: { stored_file: { description: "nothing" } }
    end
    assert_redirected_to admin_stored_files_path
    assert_equal "Choose at least one file to upload.", flash[:alert]
  end

  test "files over the size limit are rejected and nothing is saved" do
    sign_in_as(@editor)
    with_max_size(10) do
      assert_no_difference "StoredFile.count" do
        post admin_stored_files_path, params: { stored_file: { files: [ upload ] } }
      end
    end
    assert_redirected_to admin_stored_files_path
    assert_match "sample.pdf", flash[:alert]
    assert_match "too large", flash[:alert]
  end

  # Deleting
  test "editor deletes a file" do
    stored_file = StoredFile.create!(user: @editor, file: upload)
    sign_in_as(@editor)
    assert_difference "StoredFile.count", -1 do
      delete admin_stored_file_path(stored_file)
    end
    assert_redirected_to admin_stored_files_path
  end
end
