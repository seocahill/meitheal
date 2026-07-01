class ListUnpaidBookingsTool < ApplicationTool
  tool_name "list_unpaid_bookings"
  description <<~DESC.squish
    List bookings that are unpaid and not cancelled, with the booker's email so
    you can cross-reference them against payments before marking any as paid.
  DESC

  def call
    bookings = Booking.unpaid.includes(:space, :user).order(:starts_at)

    return "There are no unpaid bookings." if bookings.empty?

    bookings.map { |booking| format_line(booking) }.join("\n")
  end

  private

  def format_line(booking)
    starts = booking.starts_at&.strftime("%Y-%m-%d %H:%M")
    "##{booking.id} [#{booking.status}] #{booking.title} — #{booking.space.name}, #{starts}, " \
      "#{booking.user.email_address}"
  end
end
