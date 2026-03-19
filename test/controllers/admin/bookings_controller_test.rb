require "test_helper"

class Admin::BookingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = users(:editor)
    @viewer = users(:viewer)
    @space = spaces(:front_room)
  end

  test "editor can access bookings index" do
    sign_in_as(@editor)
    get admin_bookings_path
    assert_response :success
  end

  test "viewer cannot access bookings index" do
    sign_in_as(@viewer)
    get admin_bookings_path
    assert_redirected_to root_path
  end

  test "index shows upcoming bookings by default" do
    sign_in_as(@editor)
    past_booking = Booking.create!(
      space: @space, user: @viewer, title: "Past Booking",
      starts_at: 1.week.ago, ends_at: 1.week.ago + 1.hour,
      status: :confirmed, paid: true,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    upcoming_booking = Booking.create!(
      space: @space, user: @viewer, title: "Upcoming Booking",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 1.hour,
      status: :confirmed, paid: true,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    get admin_bookings_path
    assert_response :success
    assert_includes response.body, "Upcoming Booking"
    assert_not_includes response.body, "Past Booking"
  end

  test "index filters by pending status" do
    sign_in_as(@editor)
    pending = bookings(:pending_booking)
    confirmed = bookings(:upcoming_booking)

    get admin_bookings_path(status: "pending")
    assert_response :success
    assert_includes response.body, pending.title
  end

  test "index filters by unpaid bookings" do
    sign_in_as(@editor)
    unpaid = Booking.create!(
      space: @space, user: @viewer, title: "Unpaid Booking",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 1.hour,
      status: :confirmed, paid: false,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    get admin_bookings_path(paid: "unpaid")
    assert_response :success
    assert_includes response.body, "Unpaid Booking"
  end
end
