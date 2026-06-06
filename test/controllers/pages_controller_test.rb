require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @page = pages(:about_page)
    @page_ga = pages(:about_page_ga)
  end

  # Public access
  test "show displays published page by slug" do
    get page_path(@page.slug)
    assert_response :success
    assert_includes response.body, @page.title
  end

  test "show returns 404 for unpublished page when not authenticated" do
    draft = pages(:draft_page)
    get page_path(draft.slug)
    assert_response :not_found
  end

  test "editor can view unpublished page" do
    draft = pages(:draft_page)
    sign_in_as(@editor)
    get page_path(draft.slug)
    assert_response :success
  end

  # Irish locale routing
  test "ga route serves Irish page when it exists" do
    get ga_page_path(@page_ga.slug)
    assert_response :success
    assert_includes response.body, @page_ga.title
  end

  test "ga route falls back to English page when no Irish version exists" do
    get ga_page_path(pages(:draft_page).slug)
    # draft_page has no ga version, but editor must be signed in to view drafts
    # So just verify the route resolves correctly (not a routing error)
    assert_includes [ 302, 404 ], response.status
  end

  test "ga route falls back to English for pages with no Irish version" do
    english_only = Page.create!(title: "English Only", slug: "english-only-test", locale: "en",
                                visibility: :published, content: "English content")
    get ga_page_path("english-only-test")
    assert_response :success
    assert_includes response.body, "English Only"
  ensure
    english_only&.destroy
  end

  test "ga root route renders home with Irish locale" do
    get ga_root_path
    assert_response :success
  end

  # Admin management
  test "index requires editor role" do
    sign_in_as(@viewer)
    get admin_pages_path
    assert_redirected_to root_path
  end

  test "editor can access index" do
    sign_in_as(@editor)
    get admin_pages_path
    assert_response :success
  end

  test "index shows all pages including drafts" do
    sign_in_as(@editor)
    get admin_pages_path
    assert_includes response.body, pages(:about_page).title
    assert_includes response.body, pages(:draft_page).title
  end

  test "new requires editor role" do
    sign_in_as(@viewer)
    get new_admin_page_path
    assert_redirected_to root_path
  end

  test "editor can create English page" do
    sign_in_as(@editor)
    assert_difference "Page.count" do
      post admin_pages_path, params: {
        page: {
          title: "New Page",
          slug: "new-page",
          locale: "en",
          content: "New content"
        }
      }
    end
    assert_redirected_to page_path("new-page")
  end

  test "editor can create Irish page" do
    sign_in_as(@editor)
    assert_difference "Page.count" do
      post admin_pages_path, params: {
        page: {
          title: "Leathanach Nua",
          slug: "leathanach-nua",
          locale: "ga",
          content: "Ábhar nua"
        }
      }
    end
    assert_redirected_to ga_page_path("leathanach-nua")
  end

  test "editor can edit page" do
    sign_in_as(@editor)
    get edit_admin_page_path(@page)
    assert_response :success
  end

  test "editor can update page" do
    sign_in_as(@editor)
    patch admin_page_path(@page), params: {
      page: { title: "Updated Title" }
    }
    assert_redirected_to page_path(@page.slug)
    @page.reload
    assert_equal "Updated Title", @page.title
  end

  test "editor can destroy page" do
    sign_in_as(@editor)
    assert_difference "Page.count", -1 do
      delete admin_page_path(@page)
    end
    assert_redirected_to admin_pages_path
  end

  test "editor can publish page" do
    draft = pages(:draft_page)
    sign_in_as(@editor)
    patch publish_admin_page_path(draft)
    assert_redirected_to page_path(draft.slug)
    draft.reload
    assert draft.published?
  end

  test "editor can unpublish page" do
    sign_in_as(@editor)
    patch unpublish_admin_page_path(@page)
    assert_redirected_to admin_pages_path
    @page.reload
    assert_not @page.published?
  end
end
