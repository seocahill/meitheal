class ListTodosTool < ApplicationTool
  tool_name "list_todos"
  description "List admin todos with their id, priority and title. Pending only by default."

  arguments do
    optional(:include_completed).filled(:bool).description("Include completed todos as well as pending ones")
  end

  def call(include_completed: false)
    scope = include_completed ? AdminTodo.all : AdminTodo.pending
    todos = scope.default_order

    return "There are no todos." if todos.empty?

    todos.map { |todo| format_line(todo) }.join("\n")
  end

  private

  def format_line(todo)
    status = todo.completed? ? "done" : "pending"
    "##{todo.id} [#{todo.priority}/#{status}] #{todo.title}"
  end
end
