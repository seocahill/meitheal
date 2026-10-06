require "test_helper"

class Admin::PaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @membership = memberships(:active_membership)
  end

  def create_payment(description:, paid_on: Date.current, amount_cents: 2000, payment_method: :cash,
                     purpose: :membership, status: :completed, membership: @membership, user_name: "Test User")
    Payment.create!(
      membership: membership, amount_cents: amount_cents, paid_on: paid_on, payment_method: payment_method,
      purpose: purpose, status: status, user_email: "payer@example.com", user_name: user_name,
      description: description
    )
  end

  # Access control
  test "editors can see payments" do
    sign_in_as(@editor)
    get admin_payments_path
    assert_response :success
  end

  test "viewers cannot see payments" do
    sign_in_as(@viewer)
    get admin_payments_path
    assert_redirected_to root_path
  end

  test "signed out visitors are sent to sign in" do
    get admin_payments_path
    assert_redirected_to new_session_path
  end

  test "editors can record a payment" do
    sign_in_as(@editor)
    assert_difference "@membership.payments.count" do
      post admin_membership_payments_path(@membership), params: {
        payment: { amount_euro: "20", paid_on: Date.current, payment_method: "cash", purpose: "membership", description: "Fee" }
      }
    end
  end

  test "an amount in euros is stored in cents" do
    sign_in_as(@owner)
    post admin_membership_payments_path(@membership), params: {
      payment: { amount_euro: "12.50", paid_on: Date.current, payment_method: "cash", purpose: "donation", description: "Donation" }
    }
    assert_equal 1250, @membership.payments.order(:id).last.amount_cents
  end

  test "recording a membership payment renews an unpaid membership" do
    unpaid = Membership.create!(user: @viewer, membership_type: :full, starts_on: Date.current)
    sign_in_as(@owner)

    post admin_membership_payments_path(unpaid), params: {
      payment: { amount_euro: "20", paid_on: Date.current, payment_method: "bank_transfer", purpose: "membership", description: "Annual fee" }
    }

    assert_equal :paid, unpaid.reload.payment_status
    assert_equal Date.current.end_of_year, unpaid.expires_on
  end

  test "a payment for something other than the membership fee does not renew it" do
    unpaid = Membership.create!(user: @viewer, membership_type: :full, starts_on: Date.current)
    sign_in_as(@owner)

    post admin_membership_payments_path(unpaid), params: {
      payment: { amount_euro: "30", paid_on: Date.current, payment_method: "cash", purpose: "booking", description: "Hire" }
    }

    assert_equal :unpaid, unpaid.reload.payment_status
  end

  test "a membership payment on an associate membership does not give it an expiry" do
    associate = Membership.create!(user: @viewer, membership_type: :associate, starts_on: Date.current)
    sign_in_as(@owner)

    post admin_membership_payments_path(associate), params: {
      payment: { amount_euro: "5", paid_on: Date.current, payment_method: "cash", purpose: "membership", description: "Gift" }
    }

    assert_nil associate.reload.expires_on
  end

  test "a backdated payment keeps its date" do
    sign_in_as(@owner)
    post admin_membership_payments_path(@membership), params: {
      payment: { amount_euro: "20", paid_on: 5.days.ago.to_date, payment_method: "bank_transfer", purpose: "membership", description: "Fee" }
    }
    assert_equal 5.days.ago.to_date, @membership.payments.order(:id).last.paid_on
  end

  test "payments are recorded for members who have no approved account name" do
    unapproved = User.create!(email_address: "new@example.com", password: "password", approved: false)
    membership = Membership.create!(user: unapproved, membership_type: :full, starts_on: Date.current)
    sign_in_as(@owner)

    assert_difference "membership.payments.count" do
      post admin_membership_payments_path(membership), params: {
        payment: { amount_euro: "20", paid_on: Date.current, payment_method: "cash", purpose: "membership", description: "Fee" }
      }
    end
    assert_equal "new@example.com", membership.payments.last.user_name
  end

  test "a payment that cannot be recorded says why" do
    sign_in_as(@owner)
    assert_no_difference "Payment.count" do
      post admin_membership_payments_path(@membership), params: {
        payment: { amount_euro: "0", paid_on: Date.current, payment_method: "cash", purpose: "membership", description: "Fee" }
      }
    end
    assert_redirected_to admin_membership_path(@membership)
    assert_match(/amount/i, flash[:alert])
  end

  test "only owners can delete a payment" do
    payment = create_payment(description: "Mistake")
    sign_in_as(@editor)
    assert_no_difference "Payment.count" do
      delete admin_membership_payment_path(@membership, payment)
    end
    assert_redirected_to root_path

    sign_in_as(@owner)
    assert_difference "Payment.count", -1 do
      delete admin_membership_payment_path(@membership, payment)
    end
  end

  # Filters
  test "filters combine instead of replacing each other" do
    create_payment(description: "Cash hire deposit", payment_method: :cash, purpose: :booking)
    create_payment(description: "Transfer hire deposit", payment_method: :bank_transfer, purpose: :booking)
    create_payment(description: "Cash annual fee", payment_method: :cash, purpose: :membership)

    sign_in_as(@owner)
    get admin_payments_path(payment_method: "cash", purpose: "booking", search: "deposit")

    assert_includes response.body, "Cash hire deposit"
    assert_not_includes response.body, "Transfer hire deposit"
    assert_not_includes response.body, "Cash annual fee"
  end

  test "filter by status" do
    create_payment(description: "Went through", status: :completed)
    create_payment(description: "Never finished", status: :pending)

    sign_in_as(@owner)
    get admin_payments_path(status: "pending")

    assert_includes response.body, "Never finished"
    assert_not_includes response.body, "Went through"
  end

  test "ignores a payment method or status that does not exist" do
    create_payment(description: "Still listed")
    sign_in_as(@owner)
    get admin_payments_path(payment_method: "bitcoin", status: "bogus", purpose: "nope")
    assert_response :success
    assert_includes response.body, "Still listed"
  end

  test "date range with only a from date" do
    create_payment(description: "Ancient history", paid_on: Date.new(2020, 1, 1))
    create_payment(description: "Last week", paid_on: 1.week.ago.to_date)

    sign_in_as(@owner)
    get admin_payments_path(from: 1.month.ago.to_date.iso8601)

    assert_includes response.body, "Last week"
    assert_not_includes response.body, "Ancient history"
  end

  test "date range with only a to date" do
    create_payment(description: "Ancient history", paid_on: Date.new(2020, 1, 1))
    create_payment(description: "Last week", paid_on: 1.week.ago.to_date)

    sign_in_as(@owner)
    get admin_payments_path(to: Date.new(2021, 1, 1).iso8601)

    assert_includes response.body, "Ancient history"
    assert_not_includes response.body, "Last week"
  end

  test "date range includes the first and last day" do
    create_payment(description: "On the first", paid_on: Date.new(2026, 3, 1))
    create_payment(description: "On the last", paid_on: Date.new(2026, 3, 31))
    create_payment(description: "Day before", paid_on: Date.new(2026, 2, 28))
    create_payment(description: "Day after", paid_on: Date.new(2026, 4, 1))

    sign_in_as(@owner)
    get admin_payments_path(from: "2026-03-01", to: "2026-03-31")

    assert_includes response.body, "On the first"
    assert_includes response.body, "On the last"
    assert_not_includes response.body, "Day before"
    assert_not_includes response.body, "Day after"
  end

  test "period presets filter by date" do
    create_payment(description: "This year", paid_on: Date.current.beginning_of_year)
    create_payment(description: "Two years back", paid_on: 2.years.ago.to_date)

    sign_in_as(@owner)
    get admin_payments_path(period: "this_year")

    assert_includes response.body, "This year"
    assert_not_includes response.body, "Two years back"
  end

  test "search matches the member's current email, not just the one copied onto the payment" do
    payment = create_payment(description: "Fee", user_name: "Stale Name")
    payment.update_columns(user_email: "stale@example.com")

    sign_in_as(@owner)
    get admin_payments_path(search: @membership.user.email_address)

    assert_includes response.body, "Stale Name"
  end

  # Totals
  test "shows the total of completed payments for the current filter" do
    create_payment(description: "A", amount_cents: 2000, paid_on: Date.new(2026, 3, 1))
    create_payment(description: "B", amount_cents: 1050, paid_on: Date.new(2026, 3, 2))
    create_payment(description: "Unfinished", amount_cents: 5000, paid_on: Date.new(2026, 3, 3), status: :pending)
    create_payment(description: "Other month", amount_cents: 9900, paid_on: Date.new(2026, 4, 3))

    sign_in_as(@owner)
    get admin_payments_path(from: "2026-03-01", to: "2026-03-31")

    assert_select "[data-total]", text: /€30\.50/
    assert_select "[data-total-count]", text: /2 completed/
  end

  test "total is broken down by method" do
    create_payment(description: "A", amount_cents: 2000, payment_method: :cash)
    create_payment(description: "B", amount_cents: 1000, payment_method: :bank_transfer)

    sign_in_as(@owner)
    get admin_payments_path(search: "payer@example.com")

    assert_select "[data-method-total='cash']", text: /€20\.00/
    assert_select "[data-method-total='bank_transfer']", text: /€10\.00/
  end

  # Navigation keeps filters
  test "method tabs keep the search and date filters" do
    sign_in_as(@owner)
    get admin_payments_path(search: "mary", from: "2026-01-01", to: "2026-01-31")

    assert_select "a[href*='payment_method=cash'][href*='search=mary'][href*='from=2026-01-01'][href*='to=2026-01-31']"
  end

  test "search form keeps the method filter and shows the chosen purpose and status" do
    sign_in_as(@owner)
    get admin_payments_path(payment_method: "cash", status: "pending", purpose: "booking")

    assert_select "form input[type=hidden][name=payment_method][value=cash]"
    assert_select "form select[name=status] option[selected][value=pending]"
    assert_select "form select[name=purpose] option[selected][value=booking]"
  end

  test "period links keep the other filters" do
    sign_in_as(@owner)
    get admin_payments_path(payment_method: "cash")

    assert_select "a[href*='period=last_month'][href*='payment_method=cash']"
  end

  test "dates are shown day month year" do
    create_payment(description: "Dated", paid_on: Date.new(2026, 3, 5))
    sign_in_as(@owner)
    get admin_payments_path

    assert_includes response.body, "05 Mar 2026"
  end

  test "pagination keeps filters" do
    21.times { |i| create_payment(description: "Fee #{i}", payment_method: :cash) }
    sign_in_as(@owner)
    get admin_payments_path(payment_method: "cash")

    assert_select "nav a[href*='payment_method=cash'][href*='page=2']"
  end

  # CSV export
  test "exports the filtered payments as CSV" do
    create_payment(description: "March fee", paid_on: Date.new(2026, 3, 5), amount_cents: 2050, payment_method: :bank_transfer, user_name: "Mary Byrne")
    create_payment(description: "April fee", paid_on: Date.new(2026, 4, 5))

    sign_in_as(@owner)
    get admin_payments_path(format: :csv, from: "2026-03-01", to: "2026-03-31")

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match(/attachment; filename="payments-from-2026-03-01-to-2026-03-31\.csv"/, response.headers["Content-Disposition"])

    rows = CSV.parse(response.body, headers: true)
    assert_equal [ "Date", "Name", "Email", "Purpose", "Description", "Amount (EUR)", "Method", "Status", "Notes", "SumUp transaction" ], rows.headers
    assert_equal 1, rows.size
    assert_equal [ "2026-03-05", "Mary Byrne", "payer@example.com", "Membership", "March fee", "20.50", "Bank transfer", "Completed" ], rows.first.fields.first(8)
  end

  test "export is not paginated" do
    25.times { |i| create_payment(description: "Fee #{i}") }
    sign_in_as(@owner)
    get admin_payments_path(format: :csv, search: "payer@example.com")
    assert_equal 25, CSV.parse(response.body, headers: true).size
  end

  test "export neutralises values a spreadsheet would run as a formula" do
    create_payment(description: "=HYPERLINK(\"http://evil.example\")", user_name: "+cmd")
    sign_in_as(@owner)
    get admin_payments_path(format: :csv, search: "payer@example.com")

    row = CSV.parse(response.body, headers: true).first
    assert_equal "'+cmd", row["Name"]
    assert row["Description"].start_with?("'=")
  end

  test "viewers cannot export" do
    sign_in_as(@viewer)
    get admin_payments_path(format: :csv)
    assert_redirected_to root_path
  end

  test "export link keeps the current filters" do
    sign_in_as(@owner)
    get admin_payments_path(payment_method: "cash", period: "this_year")
    assert_select "a[href*='.csv'][href*='payment_method=cash'][href*='period=this_year']", text: /Export/
  end
end
