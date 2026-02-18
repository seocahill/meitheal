require "test_helper"

class AdminTodoTest < ActiveSupport::TestCase
  test "valid todo with required attributes" do
    todo = AdminTodo.new(title: "Test todo")
    assert todo.valid?, todo.errors.full_messages.join(", ")
  end

  test "requires title" do
    todo = AdminTodo.new
    assert_not todo.valid?
    assert_includes todo.errors[:title], "can't be blank"
  end

  test "completed defaults to false" do
    todo = AdminTodo.new(title: "Test")
    assert_equal false, todo.completed
  end

  test "priority defaults to normal" do
    todo = AdminTodo.new(title: "Test")
    assert_equal "normal", todo.priority
  end

  test "priority enum values" do
    %w[low normal high urgent].each do |priority|
      todo = AdminTodo.new(title: "Test", priority: priority)
      assert todo.valid?, "Expected priority #{priority} to be valid"
      assert_equal priority, todo.priority
    end
  end

  # Scopes
  test "pending scope returns only incomplete todos" do
    pending = AdminTodo.create!(title: "Pending")
    completed = AdminTodo.create!(title: "Done", completed: true)

    assert_includes AdminTodo.pending, pending
    assert_not_includes AdminTodo.pending, completed
  end

  test "completed scope returns only complete todos" do
    pending = AdminTodo.create!(title: "Pending")
    completed = AdminTodo.create!(title: "Done", completed: true)

    assert_includes AdminTodo.completed, completed
    assert_not_includes AdminTodo.completed, pending
  end

  test "overdue scope returns todos past due date" do
    overdue = AdminTodo.create!(title: "Overdue", due_date: 1.day.ago)
    not_overdue = AdminTodo.create!(title: "Future", due_date: 1.day.from_now)
    no_date = AdminTodo.create!(title: "No date")

    assert_includes AdminTodo.overdue, overdue
    assert_not_includes AdminTodo.overdue, not_overdue
    assert_not_includes AdminTodo.overdue, no_date
  end

  test "due_soon scope returns pending todos due within 3 days" do
    due_soon = AdminTodo.create!(title: "Soon", due_date: 2.days.from_now)
    due_today = AdminTodo.create!(title: "Today", due_date: Date.current)
    due_later = AdminTodo.create!(title: "Later", due_date: 5.days.from_now)
    overdue = AdminTodo.create!(title: "Past", due_date: 1.day.ago)

    assert_includes AdminTodo.due_soon, due_soon
    assert_includes AdminTodo.due_soon, due_today
    assert_not_includes AdminTodo.due_soon, due_later
    assert_not_includes AdminTodo.due_soon, overdue
  end

  # Instance methods
  test "overdue? returns true for past due incomplete todos" do
    todo = AdminTodo.new(title: "Test", due_date: 1.day.ago, completed: false)
    assert todo.overdue?

    todo.completed = true
    assert_not todo.overdue?

    todo.completed = false
    todo.due_date = 1.day.from_now
    assert_not todo.overdue?
  end

  test "due_soon? returns true for todos due within 3 days" do
    todo = AdminTodo.new(title: "Test", due_date: 2.days.from_now, completed: false)
    assert todo.due_soon?

    todo.completed = true
    assert_not todo.due_soon?

    todo.completed = false
    todo.due_date = 5.days.from_now
    assert_not todo.due_soon?
  end

  test "toggle_completed! toggles the completed state" do
    todo = AdminTodo.create!(title: "Test")
    assert_equal false, todo.completed

    todo.toggle_completed!
    assert_equal true, todo.reload.completed

    todo.toggle_completed!
    assert_equal false, todo.reload.completed
  end

  # Polymorphic source
  test "can have a polymorphic source" do
    todo = AdminTodo.new(title: "Follow up on email")
    assert todo.valid?
    assert_nil todo.source
  end
end
