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
    published = Page.create!(title: "Published", slug: "scope-test-published", content: "Yes", published: true)
    draft = Page.create!(title: "Draft", slug: "scope-test-draft", content: "No", published: false)

    assert_includes Page.published, published
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
end
