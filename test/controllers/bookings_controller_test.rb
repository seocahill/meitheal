require "test_helper"

class BookingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @space = spaces(:main_hall)
    @booking = bookings(:upcoming_booking)
  end

  # Public calendar
  test "calendar shows confirmed bookings to public" do
    get calendar_path
    assert_response :success
    assert_includes response.body, @booking.title
  end

  test "calendar can be filtered by month" do
    get calendar_path(month: 1.month.from_now.strftime("%Y-%m"))
    assert_response :success
  end

  # Booking management
  test "new requires authentication" do
    get new_booking_path
    assert_redirected_to new_session_path
  end

  test "authenticated user can access new booking form" do
    sign_in_as(@viewer)
    get new_booking_path
    assert_response :success
  end

  test "authenticated user can create booking" do
    sign_in_as(@viewer)
    assert_difference "Booking.count" do
      post bookings_path, params: {
        booking: {
          space_id: @space.id,
          title: "New Booking",
          starts_at: 3.weeks.from_now,
          ends_at: 3.weeks.from_now + 2.hours,
          agree_booking_rules: "1",
          agree_ethics: "1"
        }
      }
    end
    assert_redirected_to calendar_path
  end

  test "new booking defaults to pending status" do
    sign_in_as(@viewer)
    post bookings_path, params: {
      booking: {
        space_id: @space.id,
        title: "New Booking",
        starts_at: 3.weeks.from_now,
        ends_at: 3.weeks.from_now + 2.hours,
        agree_booking_rules: "1",
        agree_ethics: "1"
      }
    }
    assert Booking.last.pending?
  end

  test "booking without agreements is rejected" do
    sign_in_as(@viewer)
    assert_no_difference "Booking.count" do
      post bookings_path, params: {
        booking: {
          space_id: @space.id,
          title: "New Booking",
          starts_at: 3.weeks.from_now,
          ends_at: 3.weeks.from_now + 2.hours
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "booking owner can edit their booking" do
    sign_in_as(@editor)
    get edit_booking_path(@booking)
    assert_response :success
  end

  test "other user cannot edit booking they dont own" do
    sign_in_as(@viewer)
    get edit_booking_path(@booking)
    assert_redirected_to root_path
  end

  test "editor can confirm booking" do
    pending_booking = bookings(:pending_booking)
    sign_in_as(@editor)
    patch confirm_booking_path(pending_booking)
    assert_redirected_to calendar_path
    pending_booking.reload
    assert pending_booking.confirmed?
  end

  test "viewer cannot confirm bookings" do
    pending_booking = bookings(:pending_booking)
    sign_in_as(@viewer)
    patch confirm_booking_path(pending_booking)
    assert_redirected_to root_path
    pending_booking.reload
    assert pending_booking.pending?
  end

  test "booking owner can cancel their booking" do
    pending_booking = bookings(:pending_booking)
    sign_in_as(@viewer)
    patch cancel_booking_path(pending_booking)
    assert_redirected_to calendar_path
    pending_booking.reload
    assert pending_booking.cancelled?
  end
end
