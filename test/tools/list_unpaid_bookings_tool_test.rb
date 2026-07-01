require "test_helper"

class ListUnpaidBookingsToolTest < ActiveSupport::TestCase
  test "lists unpaid, non-cancelled bookings with the booker email" do
    paid = bookings(:upcoming_booking)
    paid.update!(paid: true)
    unpaid = bookings(:pending_booking)

    output = ListUnpaidBookingsTool.new.call

    assert_match "##{unpaid.id}", output
    assert_match unpaid.user.email_address, output
    assert_no_match(/##{paid.id}\b/, output)
  end

  test "reports when there are no unpaid bookings" do
    Booking.update_all(paid: true)
    assert_match(/no unpaid bookings/i, ListUnpaidBookingsTool.new.call)
  end
end
