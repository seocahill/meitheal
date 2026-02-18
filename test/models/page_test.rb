require "test_helper"

class PageTest < ActiveSupport::TestCase
  test "valid page with required attributes" do
    page = Page.new(
      title: "Test Page",
      slug: "test-page-valid",
      content: "Our story..."
    )
    assert page.valid?, page.errors.full_messages.join(", ")
  end

  test "requires title" do
    page = Page.new(slug: "test-no-title", content: "Content")
    assert_not page.valid?
    assert_includes page.errors[:title], "can't be blank"
  end

  test "requires slug" do
    page = Page.new(title: "Test", content: "Content")
    assert_not page.valid?
    assert_includes page.errors[:slug], "can't be blank"
  end

  test "slug must be unique" do
    Page.create!(title: "First", slug: "unique-test-slug", content: "First content")
    duplicate = Page.new(title: "Second", slug: "unique-test-slug", content: "Second content")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "slug format validation" do
    page = Page.new(title: "Test", slug: "Invalid Slug!", content: "Content")
    assert_not page.valid?
    assert_includes page.errors[:slug], "only allows lowercase letters, numbers, and hyphens"
  end

  test "valid slug formats" do
    valid_slugs = [ "test-valid-1", "test-valid-2", "test-valid-3", "test-valid-123" ]
    valid_slugs.each do |slug|
      page = Page.new(title: "Test", slug: slug, content: "Content")
      assert page.valid?, "Expected #{slug} to be valid: #{page.errors.full_messages.join(", ")}"
    end
  end

  test "published scope returns only published pages" do
    published_page = Page.create!(title: "Published", slug: "scope-test-published", content: "Yes", visibility: :published)
    draft = Page.create!(title: "Draft", slug: "scope-test-draft", content: "No", visibility: :draft)

    assert_includes Page.published, published_page
    assert_not_includes Page.published, draft
  end

  test "find_by_slug finds page by slug" do
    page = pages(:about_page)
    found = Page.find_by_slug("about")
    assert_equal page, found
  end

  test "has rich text content" do
    page = Page.create!(title: "Rich", slug: "rich-content-test", content: "<p>Rich content</p>")
    assert page.content.present?
  end

  # Nav location tests
  test "nav_location defaults to hidden" do
    page = Page.new(title: "Test", slug: "nav-default-test")
    assert_equal "hidden", page.nav_location
  end

  test "nav_location can be set to hidden, nav, footer, or dropdown" do
    %w[hidden nav footer dropdown].each do |location|
      page = Page.new(title: "Test", slug: "nav-#{location}-test", nav_location: location)
      assert page.valid?, "Expected nav_location #{location} to be valid"
      assert_equal location, page.nav_location
    end
  end

  test "scopes for nav locations" do
    nav_page = Page.create!(title: "Nav", slug: "nav-scope-nav", nav_location: :nav, visibility: :published)
    footer_page = Page.create!(title: "Footer", slug: "nav-scope-footer", nav_location: :footer, visibility: :published)
    dropdown_page = Page.create!(title: "Dropdown", slug: "nav-scope-dropdown", nav_location: :dropdown, visibility: :published)
    hidden_page = Page.create!(title: "Hidden", slug: "nav-scope-hidden", nav_location: :hidden, visibility: :published)

    assert_includes Page.in_nav, nav_page
    assert_not_includes Page.in_nav, footer_page

    assert_includes Page.in_footer, footer_page
    assert_not_includes Page.in_footer, nav_page

    assert_includes Page.in_dropdown, dropdown_page
    assert_not_includes Page.in_dropdown, nav_page
  end

  # Visibility tests
  test "visibility defaults to draft" do
    page = Page.new(title: "Test", slug: "vis-default-test")
    assert_equal "draft", page.visibility
  end

  test "visibility can be set to draft, published, or members_only" do
    { "draft" => "draft", "published" => "pub", "members_only" => "members" }.each do |vis, slug_suffix|
      page = Page.new(title: "Test", slug: "vis-#{slug_suffix}-test", visibility: vis)
      assert page.valid?, "Expected visibility #{vis} to be valid: #{page.errors.full_messages.join(", ")}"
      assert_equal vis, page.visibility
    end
  end

  test "visible_to scope for public pages" do
    public_page = Page.create!(title: "Public", slug: "vis-scope-public", visibility: :published)
    members_page = Page.create!(title: "Members", slug: "vis-scope-members", visibility: :members_only)
    draft_page = Page.create!(title: "Draft", slug: "vis-scope-draft", visibility: :draft)

    # Non-authenticated user sees only published
    assert_includes Page.visible_to(nil), public_page
    assert_not_includes Page.visible_to(nil), members_page
    assert_not_includes Page.visible_to(nil), draft_page
  end

  test "visible_to scope for members" do
    public_page = Page.create!(title: "Public", slug: "vis-member-public", visibility: :published)
    members_page = Page.create!(title: "Members", slug: "vis-member-members", visibility: :members_only)
    draft_page = Page.create!(title: "Draft", slug: "vis-member-draft", visibility: :draft)

    member = users(:viewer)

    # Member sees published and members_only
    assert_includes Page.visible_to(member), public_page
    assert_includes Page.visible_to(member), members_page
    assert_not_includes Page.visible_to(member), draft_page
  end

  test "published? returns true for published visibility" do
    page = Page.new(visibility: :published)
    assert page.published?

    page.visibility = :draft
    assert_not page.published?
  end
end
