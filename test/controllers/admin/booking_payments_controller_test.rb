require "test_helper"

class Admin::BookingPaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = users(:editor)
    @viewer = users(:viewer)
    @membership = memberships(:viewer_membership)
    @booking = Booking.create!(
      space: spaces(:front_room), user: @viewer, title: "Open Mic", status: :confirmed,
      starts_at: 1.week.from_now, ends_at: 1.week.from_now + 3.hours,
      agree_booking_rules: "1", agree_ethics: "1"
    )
  end

  def create_payment(membership: @membership, description: "Hire fee", purpose: :booking)
    Payment.create!(
      membership: membership, amount_cents: 5000, paid_on: Date.current, payment_method: :bank_transfer,
      purpose: purpose, status: :completed, user_email: membership.user.email_address,
      user_name: membership.payer_name, description: description
    )
  end

  def new_payment_params(overrides = {})
    { payment: { amount_euro: "50.00", paid_on: Date.current, payment_method: "cash", notes: "Door money" }.merge(overrides) }
  end

  test "viewers cannot reach the payment form" do
    sign_in_as(@viewer)
    get new_admin_booking_payment_path(@booking)
    assert_redirected_to root_path
  end

  test "viewers cannot record a payment" do
    sign_in_as(@viewer)
    post admin_booking_payments_path(@booking), params: new_payment_params
    assert_redirected_to root_path
    assert_not @booking.reload.paid?
  end

  test "the form lets the editor pick one of the booker's unlinked payments" do
    sign_in_as(@editor)
    mine = create_payment(description: "Transfer from Sean")
    create_payment(membership: memberships(:active_membership), description: "Somebody else's")

    get new_admin_booking_payment_path(@booking)

    assert_response :success
    assert_select "input[type=radio][name=payment_id][value=?]", mine.id.to_s
    assert_select "input[type=radio][name=payment_id]", count: 1
    assert_includes response.body, "Transfer from Sean"
    assert_not_includes response.body, "Somebody else's"
  end

  test "the form still offers recording a new payment when there is nothing to pick" do
    sign_in_as(@editor)

    get new_admin_booking_payment_path(@booking)

    assert_select "input[type=radio][name=payment_id]", count: 0
    assert_select "input[name='payment[amount_euro]']"
    assert_select "input[name='payment[paid_on]']"
    assert_select "select[name='payment[payment_method]'] option", count: Payment::OFFLINE_METHODS.size
    assert_select "input[name='payment[notes]']"
  end

  test "an unconfirmed booking cannot take a payment" do
    sign_in_as(@editor)
    pending = bookings(:pending_booking)

    get new_admin_booking_payment_path(pending)
    assert_response :not_found
  end

  test "picking an existing payment settles the booking" do
    sign_in_as(@editor)
    payment = create_payment

    assert_no_difference "Payment.count" do
      post admin_booking_payments_path(@booking), params: { payment_id: payment.id }
    end

    assert_redirected_to admin_bookings_path
    assert_equal @booking, payment.reload.booking
    assert @booking.reload.paid?
  end

  test "recording a payment settles the booking" do
    sign_in_as(@editor)

    assert_difference "@membership.payments.count" do
      post admin_booking_payments_path(@booking), params: new_payment_params
    end

    assert_redirected_to admin_bookings_path
    payment = @booking.payments.sole
    assert_equal 5000, payment.amount_cents
    assert payment.cash?
    assert_equal "Door money", payment.notes
    assert @booking.reload.paid?
  end

  test "a payment method taken online cannot be recorded by hand" do
    sign_in_as(@editor)

    assert_no_difference "Payment.count" do
      post admin_booking_payments_path(@booking), params: new_payment_params(payment_method: "sumup")
    end

    assert_redirected_to new_admin_booking_payment_path(@booking)
    assert_match "Choose cash, bank transfer or other", flash[:alert]
    assert_not @booking.reload.paid?
  end

  test "an invalid amount sends the editor back to the form with the reason" do
    sign_in_as(@editor)

    assert_no_difference "Payment.count" do
      post admin_booking_payments_path(@booking), params: new_payment_params(amount_euro: "")
    end

    assert_redirected_to new_admin_booking_payment_path(@booking)
    assert_match "Amount can't be blank", flash[:alert]
    assert_not @booking.reload.paid?
  end

  test "another booker's payment cannot be used" do
    sign_in_as(@editor)
    others = create_payment(membership: memberships(:active_membership))

    post admin_booking_payments_path(@booking), params: { payment_id: others.id }

    assert_redirected_to new_admin_booking_payment_path(@booking)
    assert_match "no longer available", flash[:alert]
    assert_nil others.reload.booking
    assert_not @booking.reload.paid?
  end

  test "the list filters survive the form and the redirect back" do
    sign_in_as(@editor)

    get new_admin_booking_payment_path(@booking, paid: "unpaid", space_id: 3, q: "mic")
    assert_select "form input[type=hidden][name=paid][value=unpaid]"
    assert_select "form input[type=hidden][name=q][value=mic]"

    post admin_booking_payments_path(@booking), params: new_payment_params.merge(paid: "unpaid", space_id: "3")
    assert_redirected_to admin_bookings_path(paid: "unpaid", space_id: "3")
  end

  # SumUp transactions
  def create_sumup_transaction(sumup_id: "tx-1", **attrs)
    SumupTransaction.create!({
      sumup_id: sumup_id, transaction_id: "txn-#{sumup_id}", amount_cents: 6000, occurred_at: 2.days.ago,
      kind: "PAYMENT", status: "SUCCESSFUL", payment_type: "POS", product_summary: "Hall hire"
    }.merge(attrs))
  end

  test "the form lists SumUp transactions that nothing accounts for" do
    sign_in_as(@editor)
    received = create_sumup_transaction(product_summary: "Hall hire Friday")
    claimed = create_sumup_transaction(sumup_id: "claimed", product_summary: "Already matched")
    @membership.payments.create!(
      amount_cents: 6000, paid_on: Date.current, payment_method: :sumup, sumup_transaction_id: claimed.transaction_id,
      user_email: "a@example.com", user_name: "A", description: "Fee"
    )

    get new_admin_booking_payment_path(@booking)

    assert_select "input[type=radio][name=sumup_transaction_id][value=?]", received.id.to_s
    assert_select "input[type=radio][name=sumup_transaction_id]", count: 1
    assert_includes response.body, "Hall hire Friday"
    assert_not_includes response.body, "Already matched"
  end

  test "picking a SumUp transaction records it as the booker's payment and settles the booking" do
    sign_in_as(@editor)
    received = create_sumup_transaction

    assert_difference "@membership.payments.count" do
      post admin_booking_payments_path(@booking), params: { sumup_transaction_id: received.id }
    end

    assert_redirected_to admin_bookings_path
    payment = @booking.payments.sole
    assert payment.sumup?
    assert_equal 6000, payment.amount_cents
    assert_equal "txn-tx-1", payment.sumup_transaction_id
    assert @booking.reload.paid?
    assert_not_includes SumupTransaction.unmatched, received
  end

  test "a SumUp transaction that has been matched in the meantime cannot be used again" do
    sign_in_as(@editor)
    received = create_sumup_transaction
    other = Booking.create!(
      space: spaces(:back_room), user: @editor, title: "Other", status: :confirmed,
      starts_at: 2.weeks.from_now, ends_at: 2.weeks.from_now + 2.hours, agree_booking_rules: "1", agree_ethics: "1"
    )
    other.attach_sumup_transaction!(received)

    assert_no_difference "Payment.count" do
      post admin_booking_payments_path(@booking), params: { sumup_transaction_id: received.id }
    end

    assert_redirected_to new_admin_booking_payment_path(@booking)
    assert_match "no longer available", flash[:alert]
    assert_not @booking.reload.paid?
  end

  # Bank statement transactions
  def create_bank_transaction(code: "BANK1", reference: "SEAN CAHILL IE12ABCD12345678901234", amount_cents: 12000, occurred_on: Date.new(2026, 10, 3))
    import = BankImport.first || BankImport.create!(user: @editor, filename: "report.csv", rows_read: 1, rows_added: 1)
    BankTransaction.create!(bank_import: import, code: code, reference: reference, amount_cents: amount_cents, occurred_on: occurred_on)
  end

  test "the form lists bank transactions that nothing accounts for" do
    sign_in_as(@editor)
    transfer = create_bank_transaction(reference: "HALL HIRE IE99ZZZZ00000000000000")
    create_bank_transaction(code: "SPENT", reference: "Gas bill", amount_cents: -8325)

    get new_admin_booking_payment_path(@booking)

    assert_select "input[type=radio][name=bank_transaction_id][value=?]", transfer.id.to_s
    assert_select "input[type=radio][name=bank_transaction_id]", count: 1
    assert_includes response.body, "HALL HIRE IE99ZZZZ00000000000000"
    assert_not_includes response.body, "Gas bill"
  end

  test "picking a bank transaction records it as the booker's payment and settles the booking" do
    sign_in_as(@editor)
    transfer = create_bank_transaction

    assert_difference "@membership.payments.count" do
      post admin_booking_payments_path(@booking), params: { bank_transaction_id: transfer.id }
    end

    assert_redirected_to admin_bookings_path
    payment = @booking.payments.sole
    assert payment.bank_transfer?
    assert_equal 12000, payment.amount_cents
    assert_equal payment, transfer.reload.payment
    assert @booking.reload.paid?
  end

  test "a bank transaction that has been matched in the meantime cannot be used again" do
    sign_in_as(@editor)
    transfer = create_bank_transaction
    other = Booking.create!(
      space: spaces(:back_room), user: @editor, title: "Other", status: :confirmed,
      starts_at: 2.weeks.from_now, ends_at: 2.weeks.from_now + 2.hours, agree_booking_rules: "1", agree_ethics: "1"
    )
    other.attach_bank_transaction!(transfer)

    assert_no_difference "Payment.count" do
      post admin_booking_payments_path(@booking), params: { bank_transaction_id: transfer.id }
    end

    assert_redirected_to new_admin_booking_payment_path(@booking)
    assert_match "no longer available", flash[:alert]
    assert_not @booking.reload.paid?
  end

  test "the form says how recent the bank transactions are and links to the upload page" do
    sign_in_as(@editor)
    create_bank_transaction(occurred_on: Date.new(2025, 12, 30))

    get new_admin_booking_payment_path(@booking)

    assert_select "[data-bank-status]", text: /30 Dec 2025/
    assert_select "[data-bank-status] a[href=?]", admin_bank_imports_path
  end

  test "the form tells the editor to upload when no bank statement has been uploaded" do
    sign_in_as(@editor)

    get new_admin_booking_payment_path(@booking)

    assert_select "[data-bank-status]", text: /No bank statement/
  end
end
