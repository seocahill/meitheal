require "test_helper"

class DailyPendingSummaryJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "job enqueues the daily pending summary email" do
    stub_service = Object.new
    stub_service.define_singleton_method(:generate) { nil }

    original_new = EmailDigestService.method(:new)
    EmailDigestService.define_singleton_method(:new) { |**_| stub_service }

    assert_enqueued_emails 1 do
      DailyPendingSummaryJob.perform_now
    end
  ensure
    EmailDigestService.define_singleton_method(:new, original_new)
  end
end
