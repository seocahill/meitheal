class DeleteTodoTool < ApplicationTool
  tool_name "delete_todo"
  description "Delete a single admin todo by its id."

  arguments do
    required(:id).filled(:integer).description("The id of the todo to delete")
  end

  def call(id:)
    todo = AdminTodo.find_by(id: id)
    return "No todo found with id #{id}." if todo.nil?

    todo.destroy
    "Deleted todo ##{id}: #{todo.title}"
  end
end
