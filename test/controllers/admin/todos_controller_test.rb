require "test_helper"

class Admin::TodosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @todo = AdminTodo.create!(title: "Test todo", priority: :normal)
  end

  # Access control tests
  test "owner can access todos index" do
    sign_in_as(@owner)
    get admin_todos_path
    assert_response :success
  end

  test "editor cannot access todos index" do
    sign_in_as(@editor)
    get admin_todos_path
    assert_redirected_to root_path
  end

  test "viewer cannot access todos index" do
    sign_in_as(@viewer)
    get admin_todos_path
    assert_redirected_to root_path
  end

  test "unauthenticated user cannot access todos" do
    get admin_todos_path
    assert_redirected_to new_session_path
  end

  # Index tests
  test "index shows pending todos by default" do
    sign_in_as(@owner)
    pending = AdminTodo.create!(title: "Pending task")
    completed = AdminTodo.create!(title: "Done task", completed: true)

    get admin_todos_path
    assert_response :success
    assert_match "Pending task", response.body
    assert_no_match(/Done task/, response.body)
  end

  test "index shows completed todos when requested" do
    sign_in_as(@owner)
    completed = AdminTodo.create!(title: "Done task", completed: true)

    get admin_todos_path(show_completed: true)
    assert_response :success
    assert_match "Done task", response.body
  end

  test "index filters todos by search query" do
    sign_in_as(@owner)
    AdminTodo.create!(title: "Follow up: Grant application")
    AdminTodo.create!(title: "Book the community hall")

    get admin_todos_path(q: "grant")
    assert_response :success
    assert_match "Grant application", response.body
    assert_no_match(/community hall/, response.body)
  end

  test "index search includes completed todos when requested" do
    sign_in_as(@owner)
    AdminTodo.create!(title: "Grant reconciliation", completed: true)

    get admin_todos_path(q: "grant", show_completed: true)
    assert_response :success
    assert_match "Grant reconciliation", response.body
  end

  # CRUD tests
  test "owner can view new todo form" do
    sign_in_as(@owner)
    get new_admin_todo_path
    assert_response :success
  end

  test "owner can create todo" do
    sign_in_as(@owner)
    assert_difference "AdminTodo.count" do
      post admin_todos_path, params: {
        admin_todo: {
          title: "New task",
          description: "Some details",
          priority: "high",
          due_date: 3.days.from_now.to_date
        }
      }
    end
    assert_redirected_to admin_todos_path
    todo = AdminTodo.last
    assert_equal "New task", todo.title
    assert_equal "high", todo.priority
  end

  test "owner can view edit form" do
    sign_in_as(@owner)
    get edit_admin_todo_path(@todo)
    assert_response :success
  end

  test "owner can update todo" do
    sign_in_as(@owner)
    patch admin_todo_path(@todo), params: {
      admin_todo: { title: "Updated title", priority: "urgent" }
    }
    assert_redirected_to admin_todos_path
    @todo.reload
    assert_equal "Updated title", @todo.title
    assert_equal "urgent", @todo.priority
  end

  test "owner can delete todo" do
    sign_in_as(@owner)
    assert_difference "AdminTodo.count", -1 do
      delete admin_todo_path(@todo)
    end
    assert_redirected_to admin_todos_path
  end

  # Toggle action
  test "owner can toggle todo completion" do
    sign_in_as(@owner)
    assert_not @todo.completed

    patch toggle_admin_todo_path(@todo)
    assert_redirected_to admin_todos_path
    assert @todo.reload.completed

    patch toggle_admin_todo_path(@todo)
    assert_not @todo.reload.completed
  end

  # Batch actions
  test "owner can batch complete todos" do
    sign_in_as(@owner)
    todo1 = AdminTodo.create!(title: "Task 1")
    todo2 = AdminTodo.create!(title: "Task 2")

    post batch_complete_admin_todos_path, params: { todo_ids: [ todo1.id, todo2.id ] }
    assert_redirected_to admin_todos_path

    assert todo1.reload.completed
    assert todo2.reload.completed
  end

  test "batch complete preserves the search filter in the redirect" do
    sign_in_as(@owner)
    todo = AdminTodo.create!(title: "Follow up: Grant")

    post batch_complete_admin_todos_path(q: "grant"), params: { todo_ids: [ todo.id ] }
    assert_redirected_to admin_todos_path(q: "grant")
  end

  test "owner can batch delete todos" do
    sign_in_as(@owner)
    todo1 = AdminTodo.create!(title: "Task 1")
    todo2 = AdminTodo.create!(title: "Task 2")

    assert_difference "AdminTodo.count", -2 do
      post batch_delete_admin_todos_path, params: { todo_ids: [ todo1.id, todo2.id ] }
    end
    assert_redirected_to admin_todos_path
  end

  # Validation tests
  test "create with invalid params shows errors" do
    sign_in_as(@owner)
    assert_no_difference "AdminTodo.count" do
      post admin_todos_path, params: {
        admin_todo: { title: "" }
      }
    end
    assert_response :unprocessable_entity
  end
end
