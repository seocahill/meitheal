class PurgeNoisyTodosTool < ApplicationTool
  tool_name "purge_noisy_todos"
  description <<~DESC.squish
    Delete pending todos that were auto-generated from noisy emails
    (security alerts, login notifications, delivery updates, and other
    automated noise). Pass dry_run to preview without deleting.
  DESC

  arguments do
    optional(:dry_run).filled(:bool).description("Report what would be purged without deleting anything")
  end

  def call(dry_run: false)
    noisy = noisy_todos
    return "No noisy todos to purge." if noisy.empty?

    titles = noisy.map { |todo| "##{todo.id} #{todo.title}" }.join("\n")

    if dry_run
      "Would purge #{noisy.size} noisy todo(s):\n#{titles}"
    else
      noisy.each(&:destroy)
      "Purged #{noisy.size} noisy todo(s):\n#{titles}"
    end
  end

  private

  def noisy_todos
    AdminTodo.pending
      .where(source_type: "CachedEmail")
      .includes(:source)
      .select { |todo| todo.source&.noise? }
  end
end
