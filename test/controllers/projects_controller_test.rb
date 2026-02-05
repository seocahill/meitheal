require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @project = posts(:project_one)
  end

  test "should get index" do
    get projects_url
    assert_response :success
  end

  test "index only shows project posts" do
    get projects_url
    assert_response :success
    # Should not contain news post titles
    assert_no_match "Test Post One", response.body
    # Should contain project titles
    assert_match "Test Project One", response.body
  end

  test "should get show for published project" do
    get project_url(@project.slug)
    assert_response :success
  end

  test "show rejects news posts" do
    news_post = posts(:one)
    get project_url(news_post.slug)
    assert_response :not_found
  end

  test "should get new when authenticated" do
    sign_in_as(@owner)
    get new_project_url
    assert_response :success
  end

  test "should create project when authenticated" do
    sign_in_as(@owner)
    assert_difference("Post.project.count") do
      post projects_url, params: { post: { title: "New Project", slug: "new-project" } }
    end
    created = Post.find_by(slug: "new-project")
    assert created.project?
    assert_redirected_to project_url("new-project")
  end

  test "should get edit when authenticated" do
    sign_in_as(@owner)
    get edit_project_url(@project.slug)
    assert_response :success
  end

  test "should update project when authenticated" do
    sign_in_as(@owner)
    patch project_url(@project.slug), params: { post: { title: "Updated Project Title" } }
    assert_redirected_to project_url(@project.slug)
  end

  test "should destroy project when authenticated" do
    sign_in_as(@owner)
    assert_difference("Post.count", -1) do
      delete project_url(@project.slug)
    end
    assert_redirected_to projects_url
  end
end
