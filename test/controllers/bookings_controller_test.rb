require "test_helper"

class BookingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @space = spaces(:front_room)
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

  test "calendar hides edit and cancel buttons from non-admin users" do
    # Create a confirmed booking owned by the viewer — they should NOT see Edit/Cancel
    viewer_booking = Booking.create!(
      space: @space, user: @viewer, title: "Viewer Booking",
      starts_at: 3.days.from_now, ends_at: 3.days.from_now + 2.hours,
      status: :confirmed, agree_booking_rules: "1", agree_ethics: "1"
    )
    sign_in_as(@viewer)
    get calendar_path
    assert_response :success
    assert_not_includes response.body, edit_booking_path(viewer_booking)
    assert_not_includes response.body, cancel_booking_path(viewer_booking)
  end

  test "calendar shows edit and cancel buttons to admin users" do
    sign_in_as(@editor)
    get calendar_path
    assert_response :success
    assert_includes response.body, edit_booking_path(@booking)
    assert_includes response.body, cancel_booking_path(@booking)
  end

  test "calendar shows import button to admin managers" do
    sign_in_as(@owner)
    get calendar_path
    assert_response :success
    assert_includes response.body, new_admin_calendar_import_path
  end

  test "calendar does not show import button to regular viewers" do
    sign_in_as(@viewer)
    get calendar_path
    assert_response :success
    assert_not_includes response.body, new_admin_calendar_import_path
  end

  # Payment tracking tests

  test "editor can mark booking as paid" do
    sign_in_as(@editor)
    unpaid_booking = Booking.create!(
      space: @space, user: @viewer, title: "Unpaid Booking",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 1.hour,
      status: :confirmed, paid: false,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    patch mark_as_paid_booking_path(unpaid_booking)
    assert_redirected_to calendar_path
    assert_equal "Booking marked as paid", flash[:notice]

    unpaid_booking.reload
    assert unpaid_booking.paid
  end

  test "viewer cannot mark booking as paid" do
    sign_in_as(@viewer)
    other_user = User.create!(email_address: "other@test.com", password: "password", approved: true)
    unpaid_booking = Booking.create!(
      space: @space, user: other_user, title: "Unpaid Booking",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 1.hour,
      status: :confirmed, paid: false,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    patch mark_as_paid_booking_path(unpaid_booking)
    assert_redirected_to root_path
    assert_equal "You don't have permission to do that.", flash[:alert]

    unpaid_booking.reload
    assert_not unpaid_booking.paid
  end

  test "marking as paid persists the status" do
    sign_in_as(@editor)
    unpaid_booking = Booking.create!(
      space: @space, user: @viewer, title: "Unpaid Booking",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 1.hour,
      status: :confirmed, paid: false,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    patch mark_as_paid_booking_path(unpaid_booking)
    unpaid_booking.reload
    assert_equal true, unpaid_booking.paid
  end
end
