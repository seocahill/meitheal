require "test_helper"

class DailyPendingSummaryJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "dispatches mail via MailerDeliveryJob so transient SMTP failures can be retried" do
    assert_enqueued_with(job: MailerDeliveryJob) do
      DailyPendingSummaryJob.perform_now
    end
  end

  test "creates todos for visible emails that don't yet have one" do
    email_without_todo = create_cached_email(subject: "New enquiry")
    email_with_todo = create_cached_email(zoho_message_id: "with_todo", subject: "Already handled")
    AdminTodo.create!(email_with_todo.to_admin_todo_attrs)

    assert_difference -> { AdminTodo.count }, 1 do
      DailyPendingSummaryJob.perform_now
    end

    todo = AdminTodo.order(:created_at).last
    assert_equal email_without_todo, todo.source
    assert_equal "Follow up: New enquiry", todo.title
  end

  test "archives emails older than one month" do
    fresh = create_cached_email(received_at: 1.day.ago)
    stale = create_cached_email(zoho_message_id: "stale", received_at: 2.months.ago)

    DailyPendingSummaryJob.perform_now

    assert_predicate fresh.reload, :unread?
    assert_predicate stale.reload, :archived?
  end

  test "skips noisy emails like security alerts and noreply notifications" do
    signal = create_cached_email(zoho_message_id: "signal", subject: "Mayo Culture Night Event Fund now Open For Applications")
    create_cached_email(zoho_message_id: "alert", subject: "Security Alert: Verify a new IP")
    create_cached_email(zoho_message_id: "noreply", from_address: "noreply@bank.com", subject: "Statement available")

    assert_difference -> { AdminTodo.count }, 1 do
      DailyPendingSummaryJob.perform_now
    end

    todo = AdminTodo.order(:created_at).last
    assert_equal signal, todo.source
  end

  test "archived emails do not get todos created" do
    create_cached_email(received_at: 2.months.ago, subject: "Old news")

    DailyPendingSummaryJob.perform_now

    assert_empty AdminTodo.where(source_type: "CachedEmail")
  end

  test "enqueues the daily pending summary email" do
    assert_enqueued_emails 1 do
      DailyPendingSummaryJob.perform_now
    end
  end

  private

  def create_cached_email(attrs = {})
    CachedEmail.create!({
      zoho_message_id: attrs.delete(:zoho_message_id) || "msg_#{SecureRandom.hex(4)}",
      zoho_folder_id: "folder_inbox",
      from_address: "sender@example.com",
      subject: "Test Email",
      summary: "Test summary",
      received_at: 1.hour.ago
    }.merge(attrs))
  end
end
