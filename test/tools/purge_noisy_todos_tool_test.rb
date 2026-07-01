require "test_helper"

class PurgeNoisyTodosToolTest < ActiveSupport::TestCase
  test "deletes todos whose source email is noise and keeps the rest" do
    noisy = cached_email(subject: "Security Alert: Verify a new IP")
    signal = cached_email(subject: "Mayo Culture Night Event Fund now Open For Applications")
    noisy_todo = AdminTodo.create!(noisy.to_admin_todo_attrs)
    signal_todo = AdminTodo.create!(signal.to_admin_todo_attrs)

    output = PurgeNoisyTodosTool.new.call

    assert_nil AdminTodo.find_by(id: noisy_todo.id)
    assert AdminTodo.find_by(id: signal_todo.id), "must keep todos sourced from genuine email"
    assert_match "1", output
  end

  test "dry run reports what would be purged without deleting" do
    noisy = cached_email(subject: "Your package is out for delivery")
    noisy_todo = AdminTodo.create!(noisy.to_admin_todo_attrs)

    output = PurgeNoisyTodosTool.new.call(dry_run: true)

    assert AdminTodo.find_by(id: noisy_todo.id), "dry run must not delete"
    assert_match(/would/i, output)
  end

  test "ignores manually-added todos that have no source email" do
    manual = AdminTodo.create!(title: "Hand-written task")

    PurgeNoisyTodosTool.new.call

    assert AdminTodo.find_by(id: manual.id)
  end

  private

  def cached_email(attrs = {})
    CachedEmail.create!({
      zoho_message_id: "msg_#{SecureRandom.hex(4)}",
      zoho_folder_id: "folder_inbox",
      from_address: "sender@example.com",
      subject: "Test",
      received_at: 1.hour.ago
    }.merge(attrs))
  end
end
