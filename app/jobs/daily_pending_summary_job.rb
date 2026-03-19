class DailyPendingSummaryJob < ApplicationJob
  queue_as :default

  def perform
    AdminMailer.daily_pending_summary.deliver_later
  end
end
