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
    get calendar_path(month: @booking.starts_at.strftime("%Y-%m"))
    assert_response :success
    assert_includes response.body, @booking.title
  end

  test "calendar can be filtered by month" do
    get calendar_path(month: 1.month.from_now.strftime("%Y-%m"))
    assert_response :success
  end

  test "calendar with invalid month param falls back to current month" do
    get calendar_path(month: "not-a-date")
    assert_response :success
  end

  test "calendar with overlong month param falls back to current month" do
    get calendar_path(month: "a" * 133)
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

  test "new booking form defaults starts_at to noon today" do
    sign_in_as(@viewer)
    today = Date.current
    travel_to today.in_time_zone.change(hour: 9, min: 30) do
      get new_booking_path
      assert_response :success
      assert_includes response.body, "#{today.iso8601}T12:00"
    end
  end

  test "new booking form defaults ends_at to 2 hours after noon today" do
    sign_in_as(@viewer)
    today = Date.current
    travel_to today.in_time_zone.change(hour: 9, min: 30) do
      get new_booking_path
      assert_response :success
      assert_includes response.body, "#{today.iso8601}T14:00"
    end
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

  test "edit form lets editors choose the booker" do
    sign_in_as(@editor)
    get edit_booking_path(bookings(:pending_booking))
    assert_response :success
    assert_select "select[name='booking[user_id]'] option[selected][value='#{@viewer.id}']"
  end

  test "edit form does not let the booker choose the booker" do
    sign_in_as(@viewer)
    get edit_booking_path(bookings(:pending_booking))
    assert_response :success
    assert_select "select[name='booking[user_id]']", count: 0
  end

  test "editor can reassign the booker" do
    sign_in_as(@editor)
    booking = bookings(:pending_booking)
    patch booking_path(booking), params: { booking: { user_id: @owner.id } }
    assert_redirected_to calendar_path
    assert_equal @owner, booking.reload.user
  end

  test "booker cannot reassign their booking to someone else" do
    sign_in_as(@viewer)
    booking = bookings(:pending_booking)
    patch booking_path(booking), params: { booking: { user_id: @owner.id } }
    assert_equal @viewer, booking.reload.user
  end

  test "a member with overdue unpaid bookings can still request a booking, which stays pending" do
    unpaid_past_booking(@viewer)
    sign_in_as(@viewer)

    assert_difference -> { @viewer.bookings.count }, 1 do
      post bookings_path, params: { booking: {
        space_id: @space.id, title: "Next gig",
        starts_at: 3.weeks.from_now, ends_at: 3.weeks.from_now + 2.hours,
        agree_booking_rules: "1", agree_ethics: "1"
      } }
    end
    assert_redirected_to calendar_path
    assert @viewer.bookings.order(:created_at).last.pending?
  end

  test "the calendar shows the owner that a pending booking's booker has unpaid bookings" do
    unpaid_past_booking(@viewer)
    sign_in_as(@owner)
    get calendar_path(month: bookings(:pending_booking).starts_at.strftime("%Y-%m"))

    assert_select "[data-unpaid-warning]", text: /1 unpaid past booking/
  end

  test "the calendar shows no unpaid warning when the booker is square" do
    sign_in_as(@owner)
    get calendar_path(month: bookings(:pending_booking).starts_at.strftime("%Y-%m"))

    assert_select "[data-unpaid-warning]", count: 0
  end

  test "a member whose annual membership lapsed is told why they cannot book" do
    expired = memberships(:expired_membership)
    sign_in_as(@editor)
    get new_booking_path

    assert_redirected_to calendar_path
    follow_redirect!
    assert_select "[data-membership-required]", text: /expired on #{expired.expires_on.strftime('%-d %B %Y')}/
    assert_select "a[href=?]", new_membership_payment_path(expired), text: /Pay your annual membership/
    assert_select "span", text: "Annual membership payment required to book"
  end

  test "the calendar tells a member who has not paid why they cannot book and how to pay" do
    user = User.create!(email_address: "assoc@example.com", password: "password123", approved: true)
    associate = user.memberships.create!(membership_type: :associate, starts_on: Date.current)
    sign_in_as(user)
    get calendar_path

    assert_select "[data-membership-required]", text: /paid annual membership/
    assert_select "a[href=?]", new_membership_payment_path(associate), text: /Pay your annual membership/
  end

  test "the calendar shows no membership notice to a member who has paid" do
    sign_in_as(@viewer)
    get calendar_path

    assert_select "[data-membership-required]", count: 0
    assert_select "a[href=?]", new_booking_path, text: "Book Space"
  end

  test "editor can confirm booking" do
    pending_booking = bookings(:pending_booking)
    sign_in_as(@editor)
    patch confirm_booking_path(pending_booking)
    assert_redirected_to calendar_path
    pending_booking.reload
    assert pending_booking.confirmed?
  end

  test "confirm records the approving user" do
    pending_booking = bookings(:pending_booking)
    sign_in_as(@editor)
    patch confirm_booking_path(pending_booking)
    pending_booking.reload
    assert_equal @editor, pending_booking.approved_by
  end

  test "confirm records the approval time" do
    pending_booking = bookings(:pending_booking)
    sign_in_as(@editor)
    freeze_time do
      patch confirm_booking_path(pending_booking)
      pending_booking.reload
      assert_equal Time.current, pending_booking.approved_at
    end
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
    get calendar_path(month: @booking.starts_at.strftime("%Y-%m"))
    assert_response :success
    assert_includes response.body, edit_booking_path(@booking)
    assert_includes response.body, cancel_booking_path(@booking)
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

  # Range display tests

  test "calendar shows multi-day booking on its start date" do
    multi_day = Booking.create!(
      space: @space, user: @owner, title: "Multi Day Event",
      starts_at: Date.current.beginning_of_month + 5.days,
      ends_at: Date.current.beginning_of_month + 8.days,
      status: :confirmed, agree_booking_rules: "1", agree_ethics: "1"
    )
    get calendar_path(month: Date.current.strftime("%Y-%m"))
    assert_response :success
    assert_includes response.body, multi_day.title
  end

  test "calendar shows multi-day booking on intermediate days" do
    start_date = Date.current.beginning_of_month + 5.days
    multi_day = Booking.create!(
      space: @space, user: @owner, title: "Multi Day Intermediate",
      starts_at: start_date,
      ends_at: start_date + 3.days,
      status: :confirmed, agree_booking_rules: "1", agree_ethics: "1"
    )
    get calendar_path(month: Date.current.strftime("%Y-%m"))
    assert_response :success
    # The title should appear at least twice (start day + intermediate days)
    assert response.body.scan(multi_day.title).length >= 2
  end

  test "calendar fetches booking that starts before month but ends within it" do
    multi_day = Booking.create!(
      space: @space, user: @owner, title: "Spans Month Boundary",
      starts_at: Date.current.beginning_of_month - 2.days,
      ends_at: Date.current.beginning_of_month + 1.day,
      status: :confirmed, agree_booking_rules: "1", agree_ethics: "1"
    )
    get calendar_path(month: Date.current.strftime("%Y-%m"))
    assert_response :success
    assert_includes response.body, multi_day.title
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

  private

  def unpaid_past_booking(user)
    Booking.create!(
      space: @space, user: user, title: "Fringe gig",
      starts_at: 3.weeks.ago, ends_at: 3.weeks.ago + 2.hours,
      status: :confirmed, paid: false,
      agree_booking_rules: "1", agree_ethics: "1"
    )
  end
end
