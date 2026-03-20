class CleanupPendingPaymentsJob < ApplicationJob
  queue_as :default

  def perform
    Payment.pending.where("created_at < ?", 24.hours.ago).destroy_all
  end
end
