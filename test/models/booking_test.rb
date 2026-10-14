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

  test "validation blocks new booking when user has unpaid confirmed bookings that ended more than 2 weeks ago" do
    Booking.create!(
      space: @space, user: @user, title: "Unpaid Booking",
      starts_at: 3.weeks.ago, ends_at: 3.weeks.ago + 1.hour,
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

  test "validation allows new booking when user has unpaid confirmed bookings that ended less than 2 weeks ago" do
    Booking.create!(
      space: @space, user: @user, title: "Unpaid Booking",
      starts_at: 1.week.ago, ends_at: 1.week.ago + 1.hour,
      paid: false, status: :confirmed,
      agree_booking_rules: "1", agree_ethics: "1"
    )

    new_booking = Booking.new(
      space: @space, user: @user, title: "New Booking",
      starts_at: 3.days.from_now, ends_at: 3.days.from_now + 1.hour,
      agree_booking_rules: "1", agree_ethics: "1"
    )
    assert new_booking.valid?
  end

  test "validation allows new booking when user has unpaid confirmed bookings that have not yet ended" do
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
    assert new_booking.valid?
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

  test "payment_overdue? is true for confirmed unpaid bookings that ended over two weeks ago" do
    booking = Booking.new(status: :confirmed, paid: false, starts_at: 1.month.ago, ends_at: 1.month.ago + 1.hour)
    assert booking.payment_overdue?
  end

  test "payment_overdue? is false when paid, recent, upcoming or not confirmed" do
    ended_long_ago = { starts_at: 1.month.ago, ends_at: 1.month.ago + 1.hour }
    assert_not Booking.new(status: :confirmed, paid: true, **ended_long_ago).payment_overdue?
    assert_not Booking.new(status: :pending, paid: false, **ended_long_ago).payment_overdue?
    assert_not Booking.new(status: :confirmed, paid: false, starts_at: 2.days.ago, ends_at: 2.days.ago + 1.hour).payment_overdue?
    assert_not Booking.new(status: :confirmed, paid: false, starts_at: 1.week.from_now, ends_at: 1.week.from_now + 1.hour).payment_overdue?
  end

  # Payments
  def create_booking(user: @user, paid: false)
    Booking.create!(
      space: @space, user: user, title: "Open Mic", status: :confirmed, paid: paid,
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 3.hours,
      agree_booking_rules: "1", agree_ethics: "1"
    )
  end

  def create_payment(membership:, purpose: :booking, status: :completed, booking: nil)
    Payment.create!(
      membership: membership, booking: booking, amount_cents: 5000, paid_on: Date.current,
      payment_method: :bank_transfer, purpose: purpose, status: status,
      user_email: membership.user.email_address, user_name: membership.payer_name, description: "Hire"
    )
  end

  test "record_payment! records a booking payment on the booker's membership and marks the booking paid" do
    booking = create_booking
    membership = memberships(:viewer_membership)

    assert_difference "membership.payments.count" do
      booking.record_payment!(amount_euro: "75.00", payment_method: :cash, paid_on: 2.days.ago.to_date, notes: "Cash at the door")
    end

    payment = booking.payments.sole
    assert_equal membership, payment.membership
    assert_equal 7500, payment.amount_cents
    assert_equal 2.days.ago.to_date, payment.paid_on
    assert payment.cash?
    assert payment.booking?
    assert payment.completed?
    assert_equal "Cash at the door", payment.notes
    assert_equal "Booking: Open Mic", payment.description
    assert_equal @user.email_address, payment.user_email
    assert booking.reload.paid?
  end

  test "record_payment! does not renew the booker's membership" do
    membership = memberships(:viewer_membership)

    assert_no_changes -> { membership.reload.expires_on } do
      create_booking.record_payment!(amount_euro: "50", payment_method: :cash)
    end
  end

  test "record_payment! gives a booker with no membership an associate one to hold the payment" do
    booking = create_booking(user: users(:owner).tap { |u| u.memberships.destroy_all })

    assert_difference "Membership.count" do
      booking.record_payment!(amount_euro: "50", payment_method: :bank_transfer)
    end

    assert booking.payments.sole.membership.associate?
  end

  test "record_payment! with an invalid payment changes nothing" do
    booking = create_booking

    assert_raises(ActiveRecord::RecordInvalid) { booking.record_payment!(amount_euro: "0", payment_method: :cash) }
    assert_not booking.reload.paid?
    assert_empty booking.payments
  end

  test "attach_payment! links an existing payment and marks the booking paid" do
    booking = create_booking
    payment = create_payment(membership: memberships(:viewer_membership))

    booking.attach_payment!(payment)

    assert_equal booking, payment.reload.booking
    assert booking.reload.paid?
  end

  test "attach_payment! refuses a payment that is not among the candidates" do
    booking = create_booking
    others = create_payment(membership: memberships(:active_membership))
    taken = create_payment(membership: memberships(:viewer_membership), booking: create_booking)

    assert_raises(ActiveRecord::RecordNotFound) { booking.attach_payment!(others) }
    assert_raises(ActiveRecord::RecordNotFound) { booking.attach_payment!(taken) }
    assert_not booking.reload.paid?
  end

  test "payment_candidates are the booker's completed payments not yet used for a booking or a membership fee" do
    booking = create_booking
    viewer = memberships(:viewer_membership)
    open_payment = create_payment(membership: viewer)
    unspecified = create_payment(membership: viewer, purpose: nil)
    create_payment(membership: viewer, purpose: :membership)
    create_payment(membership: viewer, status: :pending)
    create_payment(membership: viewer, booking: create_booking)
    create_payment(membership: memberships(:active_membership))

    assert_equal [ open_payment, unspecified ].to_set, booking.payment_candidates.to_set
  end

  test "mark_unpaid! unlinks the payments but keeps them on file" do
    booking = create_booking
    payment = create_payment(membership: memberships(:viewer_membership))
    booking.attach_payment!(payment)

    booking.mark_unpaid!

    assert_not booking.reload.paid?
    assert_nil payment.reload.booking
    assert_includes booking.payment_candidates, payment
  end

  test "deleting a booking keeps its payments" do
    booking = create_booking
    payment = create_payment(membership: memberships(:viewer_membership), booking: booking)

    booking.destroy

    assert Payment.exists?(payment.id)
    assert_nil payment.reload.booking_id
  end

  # SumUp transactions
  def create_sumup_transaction(sumup_id: "tx-1", amount_cents: 6000, occurred_at: 2.days.ago, **attrs)
    SumupTransaction.create!({
      sumup_id: sumup_id, transaction_id: "txn-#{sumup_id}", amount_cents: amount_cents, occurred_at: occurred_at,
      kind: "PAYMENT", status: "SUCCESSFUL", payment_type: "POS", product_summary: "Hall hire"
    }.merge(attrs))
  end

  test "sumup_candidates are successful SumUp transactions nothing accounts for, newest first" do
    booking = create_booking
    older = create_sumup_transaction(sumup_id: "older", occurred_at: 5.days.ago)
    newer = create_sumup_transaction(sumup_id: "newer", occurred_at: 1.day.ago)
    create_sumup_transaction(sumup_id: "refunded", status: "FAILED")
    create_sumup_transaction(sumup_id: "claimed").tap do |received|
      memberships(:active_membership).payments.create!(
        amount_cents: 6000, paid_on: Date.current, payment_method: :sumup, sumup_transaction_id: received.transaction_id,
        user_email: "a@example.com", user_name: "A", description: "Fee"
      )
    end

    assert_equal [ newer, older ], booking.sumup_candidates.to_a
  end

  test "attach_sumup_transaction! records the SumUp transaction as the booker's payment and marks the booking paid" do
    booking = create_booking
    received = create_sumup_transaction(amount_cents: 7550, occurred_at: Time.zone.local(2026, 10, 3, 21, 30))

    assert_difference "memberships(:viewer_membership).payments.count" do
      booking.attach_sumup_transaction!(received)
    end

    payment = booking.payments.sole
    assert_equal 7550, payment.amount_cents
    assert_equal Date.new(2026, 10, 3), payment.paid_on
    assert payment.sumup?
    assert payment.booking?
    assert payment.completed?
    assert_equal "txn-tx-1", payment.sumup_transaction_id
    assert_equal "Hall hire", payment.notes
    assert_equal "Booking: Open Mic", payment.description
    assert booking.reload.paid?
    assert_not_includes booking.sumup_candidates, received
  end

  test "attach_sumup_transaction! refuses a SumUp transaction that is already accounted for" do
    received = create_sumup_transaction
    create_booking.attach_sumup_transaction!(received)
    second = create_booking

    assert_raises(ActiveRecord::RecordNotFound) { second.attach_sumup_transaction!(received) }
    assert_not second.reload.paid?
  end

  test "mark_unpaid! keeps the SumUp transaction matched and offers its payment for the booking again" do
    booking = create_booking
    received = create_sumup_transaction
    booking.attach_sumup_transaction!(received)
    payment = booking.payments.sole

    booking.mark_unpaid!

    assert_not booking.reload.paid?
    assert_not_includes booking.sumup_candidates, received
    assert_includes booking.payment_candidates, payment
  end

  # Bank statement transactions
  def create_bank_transaction(code: "BANK1", reference: "SEAN CAHILL IE12ABCD12345678901234", amount_cents: 12000, occurred_on: Date.new(2026, 10, 3))
    import = BankImport.first || BankImport.create!(user: users(:editor), filename: "report.csv", rows_read: 1, rows_added: 1)
    BankTransaction.create!(bank_import: import, code: code, reference: reference, amount_cents: amount_cents, occurred_on: occurred_on)
  end

  test "bank_candidates are the bank transactions nothing accounts for" do
    booking = create_booking
    open_transfer = create_bank_transaction(code: "OPEN")
    create_bank_transaction(code: "SPENT", amount_cents: -5000)
    create_bank_transaction(code: "PAYOUT", reference: "SUMUP PID1379801 PAYOUT 171025")

    assert_equal [ open_transfer ], booking.bank_candidates.to_a
  end

  test "attach_bank_transaction! records the transfer as the booker's payment and marks the booking paid" do
    booking = create_booking
    transfer = create_bank_transaction

    assert_difference "memberships(:viewer_membership).payments.count" do
      booking.attach_bank_transaction!(transfer)
    end

    payment = booking.payments.sole
    assert_equal 12000, payment.amount_cents
    assert_equal Date.new(2026, 10, 3), payment.paid_on
    assert payment.bank_transfer?
    assert payment.booking?
    assert payment.completed?
    assert_equal "SEAN CAHILL IE12ABCD12345678901234", payment.notes
    assert_equal "Booking: Open Mic", payment.description
    assert_equal payment, transfer.reload.payment
    assert booking.reload.paid?
    assert_not_includes booking.bank_candidates, transfer
  end

  test "attach_bank_transaction! refuses a transfer that is already accounted for or is not received money" do
    taken = create_bank_transaction(code: "TAKEN")
    create_booking.attach_bank_transaction!(taken)
    spent = create_bank_transaction(code: "SPENT", amount_cents: -5000)
    booking = create_booking

    assert_raises(ActiveRecord::RecordNotFound) { booking.attach_bank_transaction!(taken) }
    assert_raises(ActiveRecord::RecordNotFound) { booking.attach_bank_transaction!(spent) }
    assert_not booking.reload.paid?
  end

  test "mark_unpaid! keeps the bank transaction matched and offers its payment for the booking again" do
    booking = create_booking
    transfer = create_bank_transaction
    booking.attach_bank_transaction!(transfer)
    payment = booking.payments.sole

    booking.mark_unpaid!

    assert_not booking.reload.paid?
    assert_not_includes booking.bank_candidates, transfer
    assert_includes booking.payment_candidates, payment
  end
end
