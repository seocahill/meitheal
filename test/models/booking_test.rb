require "test_helper"

class BookingTest < ActiveSupport::TestCase
  setup do
    @user = users(:viewer)
    @space = Space.create!(name: "Test Room")
  end

  test "valid booking with required attributes" do
    booking = Booking.new(
      space: @space,
      user: @user,
      title: "Art Workshop",
      starts_at: 1.week.from_now,
      ends_at: 1.week.from_now + 2.hours,
      agree_booking_rules: "1",
      agree_ethics: "1"
    )
    assert booking.valid?
  end

  test "requires space" do
    booking = Booking.new(user: @user, title: "Test", starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)
    assert_not booking.valid?
    assert_includes booking.errors[:space], "must exist"
  end

  test "requires user" do
    booking = Booking.new(space: @space, title: "Test", starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)
    assert_not booking.valid?
    assert_includes booking.errors[:user], "must exist"
  end

  test "requires title" do
    booking = Booking.new(space: @space, user: @user, starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour)
    assert_not booking.valid?
    assert_includes booking.errors[:title], "can't be blank"
  end

  test "requires starts_at" do
    booking = Booking.new(space: @space, user: @user, title: "Test", ends_at: 1.day.from_now + 1.hour)
    assert_not booking.valid?
    assert_includes booking.errors[:starts_at], "can't be blank"
  end

  test "requires ends_at" do
    booking = Booking.new(space: @space, user: @user, title: "Test", starts_at: 1.day.from_now)
    assert_not booking.valid?
    assert_includes booking.errors[:ends_at], "can't be blank"
  end

  test "ends_at must be after starts_at" do
    booking = Booking.new(
      space: @space,
      user: @user,
      title: "Test",
      starts_at: 1.day.from_now,
      ends_at: 1.day.from_now - 1.hour
    )
    assert_not booking.valid?
    assert_includes booking.errors[:ends_at], "must be after start time"
  end

  test "defaults to pending status" do
    booking = Booking.new
    assert_equal "pending", booking.status
  end

  test "scope confirmed returns only confirmed bookings" do
    pending_booking = Booking.create!(space: @space, user: @user, title: "Pending", starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour, status: :pending, agree_booking_rules: "1", agree_ethics: "1")
    confirmed = Booking.create!(space: @space, user: @user, title: "Confirmed", starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour, status: :confirmed, agree_booking_rules: "1", agree_ethics: "1")

    assert_includes Booking.confirmed, confirmed
    assert_not_includes Booking.confirmed, pending_booking
  end

  test "scope upcoming returns future bookings ordered by date" do
    past = Booking.create!(space: @space, user: @user, title: "Past", starts_at: 1.day.ago, ends_at: 1.day.ago + 1.hour, agree_booking_rules: "1", agree_ethics: "1")
    future = Booking.create!(space: @space, user: @user, title: "Future", starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour, agree_booking_rules: "1", agree_ethics: "1")

    assert_includes Booking.upcoming, future
    assert_not_includes Booking.upcoming, past
  end

  test "scope for_date returns bookings on a specific date" do
    today_booking = Booking.create!(space: @space, user: @user, title: "Today", starts_at: Time.current.beginning_of_day + 10.hours, ends_at: Time.current.beginning_of_day + 12.hours, agree_booking_rules: "1", agree_ethics: "1")
    tomorrow_booking = Booking.create!(space: @space, user: @user, title: "Tomorrow", starts_at: 1.day.from_now.beginning_of_day + 10.hours, ends_at: 1.day.from_now.beginning_of_day + 12.hours, agree_booking_rules: "1", agree_ethics: "1")

    results = Booking.for_date(Date.current)
    assert_includes results, today_booking
    assert_not_includes results, tomorrow_booking
  end

  test "editable_by? returns true for booking owner" do
    booking = Booking.new(user: @user)
    assert booking.editable_by?(@user)
  end

  test "editable_by? returns true for editors" do
    booking = Booking.new(user: @user)
    assert booking.editable_by?(users(:editor))
  end

  test "editable_by? returns false for other viewers" do
    other = User.create!(email_address: "other@test.com", password: "password")
    booking = Booking.new(user: @user)
    assert_not booking.editable_by?(other)
  end

  # Overlap validation on linked spaces
  test "booking on component space is rejected when composite space has overlapping booking" do
    back_room = spaces(:back_room)
    whole_building = spaces(:whole_building)

    Booking.create!(
      space: whole_building, user: @user, title: "Whole Building Event",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 2.hours,
      status: :confirmed, agree_booking_rules: "1", agree_ethics: "1"
    )

    booking = Booking.new(
      space: back_room, user: @user, title: "Back Room Session",
      starts_at: 1.week.from_now + 30.minutes, ends_at: 1.week.from_now + 1.hour,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    assert_not booking.valid?
    assert_includes booking.errors[:base], "conflicts with an existing booking on a linked space"
  end

  test "booking on composite space is rejected when component space has overlapping booking" do
    back_room = spaces(:back_room)
    whole_building = spaces(:whole_building)

    Booking.create!(
      space: back_room, user: @user, title: "Back Room Session",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 2.hours,
      status: :confirmed, agree_booking_rules: "1", agree_ethics: "1"
    )

    booking = Booking.new(
      space: whole_building, user: @user, title: "Whole Building Event",
      starts_at: 1.week.from_now + 30.minutes, ends_at: 1.week.from_now + 1.hour,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    assert_not booking.valid?
    assert_includes booking.errors[:base], "conflicts with an existing booking on a linked space"
  end

  test "booking on component space is allowed when only sibling space has overlapping booking" do
    front_room = spaces(:front_room)
    back_room = spaces(:back_room)

    Booking.create!(
      space: front_room, user: @user, title: "Front Room Event",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 2.hours,
      status: :confirmed, paid: true, agree_booking_rules: "1", agree_ethics: "1"
    )

    booking = Booking.new(
      space: back_room, user: @user, title: "Back Room Session",
      starts_at: 1.week.from_now + 30.minutes, ends_at: 1.week.from_now + 1.hour,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    assert booking.valid?
  end

  test "booking on linked space is allowed when overlapping booking is cancelled" do
    back_room = spaces(:back_room)
    whole_building = spaces(:whole_building)

    Booking.create!(
      space: whole_building, user: @user, title: "Cancelled Event",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 2.hours,
      status: :cancelled, agree_booking_rules: "1", agree_ethics: "1"
    )

    booking = Booking.new(
      space: back_room, user: @user, title: "Back Room Session",
      starts_at: 1.week.from_now + 30.minutes, ends_at: 1.week.from_now + 1.hour,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    assert booking.valid?
  end

  test "non-overlapping times on linked spaces are allowed" do
    back_room = spaces(:back_room)
    whole_building = spaces(:whole_building)

    Booking.create!(
      space: whole_building, user: @user, title: "Morning Event",
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 2.hours,
      status: :confirmed, paid: true, agree_booking_rules: "1", agree_ethics: "1"
    )

    booking = Booking.new(
      space: back_room, user: @user, title: "Afternoon Session",
      starts_at: 1.week.from_now + 3.hours, ends_at: 1.week.from_now + 5.hours,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    assert booking.valid?
  end

  # Payment tracking tests

  test "paid defaults to false on create" do
    booking = Booking.create!(
      space: @space, user: @user, title: "Test",
      starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    assert_equal false, booking.paid
  end

  test "unpaid scope returns only unpaid non-cancelled bookings" do
    user1 = User.create!(email_address: "user1@test.com", password: "password", approved: true)
    user2 = User.create!(email_address: "user2@test.com", password: "password", approved: true)
    user3 = User.create!(email_address: "user3@test.com", password: "password", approved: true)

    paid_booking = Booking.create!(
      space: @space, user: user1, title: "Paid",
      starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour,
      paid: true, status: :confirmed,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    unpaid_confirmed = Booking.create!(
      space: @space, user: user2, title: "Unpaid Confirmed",
      starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour,
      paid: false, status: :confirmed,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    unpaid_cancelled = Booking.create!(
      space: @space, user: user3, title: "Unpaid Cancelled",
      starts_at: 3.days.from_now, ends_at: 3.days.from_now + 1.hour,
      paid: false, status: :cancelled,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    unpaid = Booking.unpaid
    assert_includes unpaid, unpaid_confirmed
    assert_not_includes unpaid, paid_booking
    assert_not_includes unpaid, unpaid_cancelled
  end

  test "validation blocks new booking when user has unpaid confirmed bookings" do
    Booking.create!(
      space: @space, user: @user, title: "Unpaid Booking",
      starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour,
      paid: false, status: :confirmed,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    new_booking = Booking.new(
      space: @space, user: @user, title: "New Booking",
      starts_at: 3.days.from_now, ends_at: 3.days.from_now + 1.hour,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    assert_not new_booking.valid?
    assert_includes new_booking.errors[:base], "You have unpaid bookings. Please settle outstanding payments before making a new booking."
  end

  test "validation allows new booking when user has no unpaid bookings" do
    booking = Booking.new(
      space: @space, user: @user, title: "New Booking",
      starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    assert booking.valid?
  end

  test "validation allows new booking when unpaid bookings are cancelled" do
    Booking.create!(
      space: @space, user: @user, title: "Cancelled Unpaid",
      starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour,
      paid: false, status: :cancelled,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    new_booking = Booking.new(
      space: @space, user: @user, title: "New Booking",
      starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    assert new_booking.valid?
  end

  test "validation allows new booking when user has paid all bookings" do
    Booking.create!(
      space: @space, user: @user, title: "Paid Booking",
      starts_at: 1.day.from_now, ends_at: 1.day.from_now + 1.hour,
      paid: true, status: :confirmed,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    new_booking = Booking.new(
      space: @space, user: @user, title: "New Booking",
      starts_at: 2.days.from_now, ends_at: 2.days.from_now + 1.hour,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    assert new_booking.valid?
  end
end
