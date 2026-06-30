require "test_helper"

class ListTodosToolTest < ActiveSupport::TestCase
  test "lists pending todos with id, priority and title" do
    todo = AdminTodo.create!(title: "Call the council", priority: :high)
    AdminTodo.create!(title: "Done thing", completed: true)

    output = ListTodosTool.new.call

    assert_match "Call the council", output
    assert_match todo.id.to_s, output
    assert_match "high", output
    assert_no_match(/Done thing/, output)
  end

  test "includes completed todos when requested" do
    AdminTodo.create!(title: "Done thing", completed: true)

    output = ListTodosTool.new.call(include_completed: true)

    assert_match "Done thing", output
  end

  test "reports when there are no todos" do
    assert_match(/no .*todos/i, ListTodosTool.new.call)
  end
end
