require "test_helper"

class DeleteTodoToolTest < ActiveSupport::TestCase
  test "deletes the todo with the given id" do
    todo = AdminTodo.create!(title: "Bad item")

    assert_difference -> { AdminTodo.count }, -1 do
      output = DeleteTodoTool.new.call(id: todo.id)
      assert_match "Bad item", output
    end
    assert_nil AdminTodo.find_by(id: todo.id)
  end

  test "reports when no todo matches the id" do
    output = DeleteTodoTool.new.call(id: 999_999)
    assert_match(/no todo found/i, output)
  end

  test "rejects a missing id through schema validation" do
    assert_raises(FastMcp::Tool::InvalidArgumentsError) do
      DeleteTodoTool.new.call_with_schema_validation!
    end
  end
end
