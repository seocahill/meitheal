require "test_helper"

class DailyPendingSummaryJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "job enqueues the daily pending summary email" do
    assert_enqueued_email_with AdminMailer, :daily_pending_summary do
      DailyPendingSummaryJob.perform_now
    end
  end
end
