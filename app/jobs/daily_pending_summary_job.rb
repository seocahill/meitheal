class DailyPendingSummaryJob < ApplicationJob
  queue_as :default

  def perform
    digest = EmailDigestService.new.generate
    AdminMailer.daily_pending_summary(email_digest: digest).deliver_later
  end
end
