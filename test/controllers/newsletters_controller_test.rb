require "test_helper"

class NewslettersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @newsletter = newsletters(:monthly_update)
  end

  # Access control
  test "index requires editor role" do
    sign_in_as(@viewer)
    get newsletters_path
    assert_redirected_to root_path
  end

  test "editor can access index" do
    sign_in_as(@editor)
    get newsletters_path
    assert_response :success
  end

  test "index shows newsletters" do
    sign_in_as(@editor)
    get newsletters_path
    assert_includes response.body, @newsletter.subject
  end

  test "new requires editor role" do
    sign_in_as(@viewer)
    get new_newsletter_path
    assert_redirected_to root_path
  end

  test "editor can access new" do
    sign_in_as(@editor)
    get new_newsletter_path
    assert_response :success
  end

  test "editor can create newsletter" do
    sign_in_as(@editor)
    assert_difference "Newsletter.count" do
      post newsletters_path, params: {
        newsletter: {
          subject: "New Newsletter",
          content: "Newsletter content here"
        }
      }
    end
    assert_redirected_to edit_newsletter_path(Newsletter.last)
  end

  test "show displays newsletter" do
    sign_in_as(@editor)
    get newsletter_path(@newsletter)
    assert_response :success
    assert_includes response.body, @newsletter.subject
  end

  test "editor can edit newsletter" do
    sign_in_as(@editor)
    get edit_newsletter_path(@newsletter)
    assert_response :success
  end

  test "editor can update newsletter" do
    sign_in_as(@editor)
    patch newsletter_path(@newsletter), params: {
      newsletter: { subject: "Updated Subject" }
    }
    assert_redirected_to edit_newsletter_path(@newsletter)
    @newsletter.reload
    assert_equal "Updated Subject", @newsletter.subject
  end

  test "editor can delete draft newsletter" do
    sign_in_as(@editor)
    assert_difference "Newsletter.count", -1 do
      delete newsletter_path(@newsletter)
    end
    assert_redirected_to newsletters_path
  end

  test "cannot delete sent newsletter" do
    sent = newsletters(:sent_newsletter)
    sign_in_as(@editor)
    assert_no_difference "Newsletter.count" do
      delete newsletter_path(sent)
    end
    assert_redirected_to newsletters_path
  end
end
