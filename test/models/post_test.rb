require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "default post_type is news" do
    post = Post.new(title: "Test", user: users(:owner))
    assert_equal "news", post.post_type
  end

  test "news scope returns only news posts" do
    news_posts = Post.news
    assert news_posts.all?(&:news?)
    assert_not news_posts.any?(&:project?)
  end

  test "project scope returns only project posts" do
    project_posts = Post.project
    assert project_posts.all?(&:project?)
    assert_not project_posts.any?(&:news?)
  end

  test "published scope filters by published_at" do
    published = Post.published
    assert published.all? { |p| p.published_at.present? && p.published_at <= Time.current }
  end

  test "slug is auto-generated from title" do
    post = Post.new(title: "My Great Post", user: users(:owner))
    post.valid?
    assert_equal "my-great-post", post.slug
  end

  test "slug uniqueness generates suffix" do
    Post.create!(title: "Duplicate", slug: "duplicate", user: users(:owner))
    post = Post.new(title: "Duplicate", user: users(:editor))
    post.valid?
    assert_equal "duplicate-1", post.slug
  end
end
