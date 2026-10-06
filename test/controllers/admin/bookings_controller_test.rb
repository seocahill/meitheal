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

  test "editor can toggle booking from unpaid to paid" do
    sign_in_as(@editor)
    booking = Booking.create!(
      space: @space, user: @viewer, title: "Test Booking",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 1.hour,
      status: :confirmed, paid: false,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    patch toggle_paid_admin_booking_path(booking)
    assert_redirected_to admin_bookings_path
    assert booking.reload.paid?
  end

  test "editor can toggle booking from paid to unpaid" do
    sign_in_as(@editor)
    booking = Booking.create!(
      space: @space, user: @viewer, title: "Test Booking",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 1.hour,
      status: :confirmed, paid: true,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    patch toggle_paid_admin_booking_path(booking)
    assert_redirected_to admin_bookings_path
    assert_not booking.reload.paid?
  end

  test "viewer cannot toggle paid status" do
    sign_in_as(@viewer)
    booking = Booking.create!(
      space: @space, user: @viewer, title: "Test Booking",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 1.hour,
      status: :confirmed, paid: false,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    patch toggle_paid_admin_booking_path(booking)
    assert_redirected_to root_path
  end

  # Payment follow-up
  def create_booking(title:, starts_at:, paid: false, status: :confirmed, user: @viewer, space: @space)
    Booking.create!(
      space: space, user: user, title: title,
      starts_at: starts_at, ends_at: starts_at + 1.hour,
      status: status, paid: paid,
      agree_booking_rules: "1", agree_ethics: "1"
    )
  end

  test "unpaid filter includes confirmed bookings that already happened" do
    sign_in_as(@editor)
    create_booking(title: "Happened Last Month", starts_at: 1.month.ago, user: users(:owner))
    create_booking(title: "Coming Up Unpaid", starts_at: 1.week.from_now)
    create_booking(title: "Settled Booking", starts_at: 1.week.from_now, paid: true, user: @editor)

    get admin_bookings_path(paid: "unpaid")
    assert_includes response.body, "Happened Last Month"
    assert_includes response.body, "Coming Up Unpaid"
    assert_not_includes response.body, "Settled Booking"
  end

  test "unpaid bookings are listed oldest first so the longest outstanding is on top" do
    sign_in_as(@editor)
    create_booking(title: "Newer Unpaid", starts_at: 2.days.ago, user: users(:owner))
    create_booking(title: "Older Unpaid", starts_at: 10.days.ago)

    get admin_bookings_path(paid: "unpaid")
    assert_operator response.body.index("Older Unpaid"), :<, response.body.index("Newer Unpaid")
  end

  test "overdue filter shows only unpaid bookings that ended more than two weeks ago" do
    sign_in_as(@editor)
    create_booking(title: "Long Overdue", starts_at: 1.month.ago, user: users(:owner))
    create_booking(title: "Recently Happened", starts_at: 3.days.ago)

    get admin_bookings_path(overdue: "1")
    assert_includes response.body, "Long Overdue"
    assert_not_includes response.body, "Recently Happened"
  end

  test "when=past shows only bookings that have already started" do
    sign_in_as(@editor)
    create_booking(title: "Past One", starts_at: 1.week.ago, paid: true)
    create_booking(title: "Future One", starts_at: 1.week.from_now, paid: true)

    get admin_bookings_path(when: "past")
    assert_includes response.body, "Past One"
    assert_not_includes response.body, "Future One"
  end

  test "when=all shows past and future bookings" do
    sign_in_as(@editor)
    create_booking(title: "Past One", starts_at: 1.week.ago, paid: true)
    create_booking(title: "Future One", starts_at: 1.week.from_now, paid: true)

    get admin_bookings_path(when: "all")
    assert_includes response.body, "Past One"
    assert_includes response.body, "Future One"
  end

  test "space filter narrows the list" do
    sign_in_as(@editor)
    create_booking(title: "Front Room Gig", starts_at: 1.week.from_now, space: spaces(:front_room))
    create_booking(title: "Back Room Gig", starts_at: 1.week.from_now, space: spaces(:back_room), user: @editor)

    get admin_bookings_path(space_id: spaces(:back_room).id)
    assert_includes response.body, "Back Room Gig"
    assert_not_includes response.body, "Front Room Gig"
  end

  test "search matches booking title and booker email" do
    sign_in_as(@editor)
    create_booking(title: "Acoustic Night", starts_at: 1.week.from_now)
    create_booking(title: "Film Screening", starts_at: 2.weeks.from_now, user: @editor)

    get admin_bookings_path(q: "acoustic")
    assert_includes response.body, "Acoustic Night"
    assert_not_includes response.body, "Film Screening"

    get admin_bookings_path(q: @editor.email_address)
    assert_includes response.body, "Film Screening"
    assert_not_includes response.body, "Acoustic Night"
  end

  test "filter tabs show how many bookings are unpaid and overdue" do
    sign_in_as(@editor)
    create_booking(title: "Overdue One", starts_at: 1.month.ago, user: users(:owner))
    create_booking(title: "Unpaid Two", starts_at: 1.week.from_now)

    get admin_bookings_path
    assert_select "a[data-count=unpaid]", text: /#{Booking.confirmed.unpaid.count}/
    assert_select "a[data-count=overdue]", text: /#{Booking.confirmed.unpaid.overdue.count}/
  end

  test "toggling paid returns to the same filtered list" do
    sign_in_as(@editor)
    booking = create_booking(title: "Chase Me", starts_at: 1.month.ago)

    patch toggle_paid_admin_booking_path(booking), params: { paid: "unpaid", space_id: @space.id }
    assert_redirected_to admin_bookings_path(paid: "unpaid", space_id: @space.id)
    assert booking.reload.paid?
  end

  # Date filters
  test "date range lists bookings from the past and the future that start inside it" do
    sign_in_as(@editor)
    create_booking(title: "March Opening", starts_at: Time.zone.local(2026, 3, 1, 0, 30), paid: true)
    create_booking(title: "March Closing", starts_at: Time.zone.local(2026, 3, 31, 23, 0), paid: true)
    create_booking(title: "February Last", starts_at: Time.zone.local(2026, 2, 28, 23, 0), paid: true)
    create_booking(title: "April First", starts_at: Time.zone.local(2026, 4, 1, 0, 0), paid: true)

    get admin_bookings_path(from: "2026-03-01", to: "2026-03-31")

    assert_includes response.body, "March Opening"
    assert_includes response.body, "March Closing"
    assert_not_includes response.body, "February Last"
    assert_not_includes response.body, "April First"
  end

  test "date range with only a from date" do
    sign_in_as(@editor)
    create_booking(title: "Long Ago", starts_at: Time.zone.local(2024, 1, 10, 12), paid: true)
    create_booking(title: "Recent Past", starts_at: 1.week.ago, paid: true)

    get admin_bookings_path(from: 1.month.ago.to_date.iso8601)

    assert_includes response.body, "Recent Past"
    assert_not_includes response.body, "Long Ago"
  end

  test "date range with only a to date" do
    sign_in_as(@editor)
    create_booking(title: "Long Ago", starts_at: Time.zone.local(2024, 1, 10, 12), paid: true)
    create_booking(title: "Next Week", starts_at: 1.week.from_now, paid: true)

    get admin_bookings_path(to: Date.new(2025, 1, 1).iso8601)

    assert_includes response.body, "Long Ago"
    assert_not_includes response.body, "Next Week"
  end

  test "period preset filters by when bookings start" do
    sign_in_as(@editor)
    create_booking(title: "Two Years Back", starts_at: 2.years.ago, paid: true)
    create_booking(title: "Earlier This Year", starts_at: Date.current.beginning_of_year.in_time_zone + 10.hours, paid: true)

    get admin_bookings_path(period: "this_year")

    assert_includes response.body, "Earlier This Year"
    assert_not_includes response.body, "Two Years Back"
  end

  test "date range combines with the payment filter" do
    sign_in_as(@editor)
    create_booking(title: "March Unpaid", starts_at: Time.zone.local(2026, 3, 10, 12), paid: false, user: users(:owner))
    create_booking(title: "March Paid", starts_at: Time.zone.local(2026, 3, 11, 12), paid: true)
    create_booking(title: "May Unpaid", starts_at: Time.zone.local(2026, 5, 10, 12), paid: false, user: @editor)

    get admin_bookings_path(paid: "unpaid", from: "2026-03-01", to: "2026-03-31")

    assert_includes response.body, "March Unpaid"
    assert_not_includes response.body, "March Paid"
    assert_not_includes response.body, "May Unpaid"
  end

  test "tabs and the search form keep the date range" do
    sign_in_as(@editor)
    get admin_bookings_path(from: "2026-03-01", to: "2026-03-31", q: "x")

    assert_select "a[href*='paid=unpaid'][href*='from=2026-03-01'][href*='to=2026-03-31']"
    assert_select "form input[type=date][name=from][value='2026-03-01']"
    assert_select "form input[type=date][name=to][value='2026-03-31']"
  end

  test "toggling paid returns to the same date range" do
    sign_in_as(@editor)
    booking = create_booking(title: "Chase Me", starts_at: Time.zone.local(2026, 3, 10, 12))

    patch toggle_paid_admin_booking_path(booking), params: { from: "2026-03-01", to: "2026-03-31", period: "" }
    assert_redirected_to admin_bookings_path(from: "2026-03-01", to: "2026-03-31")
  end
end
