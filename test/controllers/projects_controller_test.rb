require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @project = posts(:project_one)
    @draft_project = posts(:project_draft)
  end

  # Public access tests
  test "should get index" do
    get projects_url
    assert_response :success
  end

  test "index only shows project posts" do
    get projects_url
    assert_response :success
    assert_no_match "Test Post One", response.body
    assert_match "Test Project One", response.body
  end

  test "index hides draft projects from unauthenticated users" do
    get projects_url
    assert_no_match @draft_project.title, response.body
  end

  test "index shows draft projects to logged in users" do
    sign_in_as(@viewer)
    get projects_url
    assert_match @draft_project.title, response.body
  end

  test "index labels draft projects as draft: for discussion" do
    sign_in_as(@viewer)
    get projects_url
    assert_match "draft: for discussion", response.body
  end

  test "index does not show draft label on published projects" do
    sign_in_as(@viewer)
    get projects_url
    # The published project title should appear without the badge next to it
    assert_match @project.title, response.body
    # Only one badge total (for the one draft)
    assert_equal 1, response.body.scan("draft: for discussion").length
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

  test "show redirects for draft project when not signed in" do
    get project_url(@draft_project.slug)
    assert_redirected_to projects_path
  end

  test "editor can view draft project" do
    sign_in_as(@editor)
    get project_url(@draft_project.slug)
    assert_response :success
  end

  # New/Create tests
  test "new requires authentication" do
    get new_project_url
    assert_redirected_to new_session_path
  end

  test "should get new when authenticated" do
    sign_in_as(@viewer)
    get new_project_url
    assert_response :success
  end

  test "new form renders form fields" do
    sign_in_as(@viewer)
    get new_project_url
    assert_response :success
    assert_select "form" do
      assert_select "input[name='post[title]']"
      assert_select "input[name='post[featured_image]']"
    end
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

  # Edit tests
  test "edit requires authentication" do
    get edit_project_url(@project.slug)
    assert_redirected_to new_session_path
  end

  test "owner can edit their project" do
    sign_in_as(@owner)
    get edit_project_url(@project.slug)
    assert_response :success
  end

  test "editor can edit any project" do
    sign_in_as(@editor)
    get edit_project_url(@project.slug)
    assert_response :success
  end

  test "viewer cannot edit project they dont own" do
    sign_in_as(@viewer)
    get edit_project_url(@project.slug)
    assert_redirected_to root_path
  end

  test "edit form renders form fields" do
    sign_in_as(@editor)
    get edit_project_url(@project.slug)
    assert_response :success
    assert_select "form" do
      assert_select "input[name='post[title]']"
      assert_select "input[name='post[featured_image]']"
    end
  end

  # Update tests
  test "editor can update any project" do
    sign_in_as(@editor)
    patch project_url(@project.slug), params: { post: { title: "Updated By Editor" } }
    assert_redirected_to project_url(@project.slug)
    @project.reload
    assert_equal "Updated By Editor", @project.title
  end

  test "owner can update their project" do
    sign_in_as(@owner)
    patch project_url(@project.slug), params: { post: { title: "Updated Project Title" } }
    assert_redirected_to project_url(@project.slug)
  end

  test "viewer cannot update project they dont own" do
    sign_in_as(@viewer)
    patch project_url(@project.slug), params: { post: { title: "Hacked" } }
    assert_redirected_to root_path
    @project.reload
    assert_not_equal "Hacked", @project.title
  end

  # Destroy tests
  test "should destroy project when authenticated as owner" do
    sign_in_as(@owner)
    assert_difference("Post.count", -1) do
      delete project_url(@project.slug)
    end
    assert_redirected_to projects_url
  end

  test "viewer cannot destroy project they dont own" do
    sign_in_as(@viewer)
    assert_no_difference("Post.count") do
      delete project_url(@project.slug)
    end
    assert_redirected_to root_path
  end

  # Publish tests
  test "editor can publish project" do
    sign_in_as(@editor)
    patch publish_project_url(@draft_project.slug)
    assert_redirected_to project_url(@draft_project.slug)
    @draft_project.reload
    assert @draft_project.published?
  end

  test "viewer cannot publish project" do
    sign_in_as(@viewer)
    patch publish_project_url(@draft_project.slug)
    assert_redirected_to root_path
    @draft_project.reload
    assert_not @draft_project.published?
  end

  test "editor can unpublish project" do
    sign_in_as(@editor)
    patch unpublish_project_url(@project.slug)
    assert_redirected_to project_url(@project.slug)
    @project.reload
    assert_not @project.published?
  end
end
