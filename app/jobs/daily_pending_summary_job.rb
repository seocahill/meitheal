class DailyPendingSummaryJob < ApplicationJob
  queue_as :default

  ARCHIVE_AFTER = 1.month

  def perform
    archive_stale_emails
    new_todos = create_todos_for_unprocessed_emails
    AdminMailer.daily_pending_summary(new_todos: new_todos).deliver_later
  end

  private

  def archive_stale_emails
    CachedEmail.visible.where(received_at: ...ARCHIVE_AFTER.ago).update_all(status: :archived)
  end

  def create_todos_for_unprocessed_emails
    CachedEmail.visible.without_admin_todo.order(received_at: :desc).map do |email|
      AdminTodo.create!(email.to_admin_todo_attrs)
    end
  end
end
