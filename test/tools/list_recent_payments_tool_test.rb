require "test_helper"

class ListRecentPaymentsToolTest < ActiveSupport::TestCase
  test "lists recent payments and can filter by purpose" do
    membership = memberships(:active_membership)
    booking_payment = create_payment(membership, description: "Room hire", purpose: :booking,
                                      user_email: "editor@example.com")
    membership_payment = create_payment(membership, description: "Annual dues", purpose: :membership,
                                        user_email: "someone@example.com")

    all = ListRecentPaymentsTool.new.call
    assert_match "##{booking_payment.id}", all
    assert_match "editor@example.com", all

    only_bookings = ListRecentPaymentsTool.new.call(purpose: "booking")
    assert_match "##{booking_payment.id}", only_bookings
    assert_no_match(/##{membership_payment.id}\b/, only_bookings)
  end

  private

  def create_payment(membership, attrs = {})
    Payment.create!({
      membership: membership,
      amount_cents: 5000,
      description: "Payment",
      paid_on: Date.current,
      payment_method: :cash,
      user_email: "payer@example.com",
      user_name: "Payer"
    }.merge(attrs))
  end
end
