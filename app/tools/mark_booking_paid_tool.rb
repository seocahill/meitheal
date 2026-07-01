class MarkBookingPaidTool < ApplicationTool
  tool_name "mark_booking_paid"
  description "Mark a booking as paid, once you have confirmed a matching payment was received."

  arguments do
    required(:id).filled(:integer).description("The id of the booking to mark paid")
  end

  def call(id:)
    booking = Booking.find_by(id: id)
    return "No booking found with id #{id}." if booking.nil?
    return "Booking ##{id} is already marked paid." if booking.paid?

    booking.update!(paid: true)
    "Marked booking ##{id} (#{booking.title}) as paid."
  end
end
