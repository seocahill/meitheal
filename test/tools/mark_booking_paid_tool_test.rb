require "test_helper"

class MarkBookingPaidToolTest < ActiveSupport::TestCase
  test "marks an unpaid booking as paid" do
    booking = bookings(:pending_booking)

    output = MarkBookingPaidTool.new.call(id: booking.id)

    assert_predicate booking.reload, :paid?
    assert_match(/marked/i, output)
  end

  test "notes when the booking is already paid" do
    booking = bookings(:upcoming_booking)
    booking.update!(paid: true)

    output = MarkBookingPaidTool.new.call(id: booking.id)

    assert_match(/already/i, output)
  end

  test "reports when no booking matches the id" do
    assert_match(/no booking found/i, MarkBookingPaidTool.new.call(id: 999_999))
  end
end
