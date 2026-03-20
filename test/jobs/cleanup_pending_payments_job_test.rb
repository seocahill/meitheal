require "test_helper"

class CleanupPendingPaymentsJobTest < ActiveJob::TestCase
  test "destroys pending payments older than 24 hours" do
    membership = memberships(:active_membership)
    stale = membership.payments.create!(
      amount_cents: 1000, paid_on: Date.current, payment_method: :sumup,
      status: :pending, user_email: "a@b.com", user_name: "Test", description: "Stale"
    )
    stale.update_column(:created_at, 25.hours.ago)

    recent = membership.payments.create!(
      amount_cents: 2000, paid_on: Date.current, payment_method: :sumup,
      status: :pending, user_email: "a@b.com", user_name: "Test", description: "Recent"
    )

    completed = membership.payments.create!(
      amount_cents: 3000, paid_on: Date.current, payment_method: :sumup,
      status: :completed, user_email: "a@b.com", user_name: "Test", description: "Done"
    )
    completed.update_column(:created_at, 25.hours.ago)

    CleanupPendingPaymentsJob.perform_now

    assert_raises(ActiveRecord::RecordNotFound) { stale.reload }
    assert_nothing_raised { recent.reload }
    assert_nothing_raised { completed.reload }
  end
end
