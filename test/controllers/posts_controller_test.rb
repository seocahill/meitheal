require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @post = posts(:one)
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should get show for published post" do
    get post_url(@post.slug)
    assert_response :success
  end

  test "should get new when authenticated" do
    sign_in_as(@owner)
    get new_post_url
    assert_response :success
  end

  test "should create post when authenticated" do
    sign_in_as(@owner)
    assert_difference("Post.count") do
      post posts_url, params: { post: { title: "New Post", slug: "new-post" } }
    end
    assert_redirected_to post_url("new-post")
  end

  test "should get edit when authenticated" do
    sign_in_as(@owner)
    get edit_post_url(@post.slug)
    assert_response :success
  end

  test "should update post when authenticated" do
    sign_in_as(@owner)
    patch post_url(@post.slug), params: { post: { title: "Updated Title" } }
    assert_redirected_to post_url(@post.slug)
  end

  test "should destroy post when authenticated" do
    sign_in_as(@owner)
    assert_difference("Post.count", -1) do
      delete post_url(@post.slug)
    end
    assert_redirected_to posts_url
  end
end
