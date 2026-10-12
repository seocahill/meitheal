require "test_helper"

class Admin::MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @membership = memberships(:active_membership)
  end

  # Access control
  test "editors can see the list and a membership" do
    sign_in_as(@editor)
    get admin_memberships_path
    assert_response :success
    get admin_membership_path(@membership)
    assert_response :success
  end

  test "viewers cannot see memberships" do
    sign_in_as(@viewer)
    get admin_memberships_path
    assert_redirected_to root_path
    get admin_membership_path(@membership)
    assert_redirected_to root_path
  end

  test "editors can create and edit memberships" do
    sign_in_as(@editor)

    get new_admin_membership_path
    assert_response :success
    assert_difference "Membership.count" do
      post admin_memberships_path, params: { membership: { user_id: @viewer.id, membership_type: "youth", starts_on: Date.current } }
    end
    assert_redirected_to admin_membership_path(Membership.order(:id).last)

    get edit_admin_membership_path(@membership)
    assert_response :success
    patch admin_membership_path(@membership), params: { membership: { membership_type: "youth" } }
    assert_redirected_to admin_membership_path(@membership)
    assert_equal "youth", @membership.reload.membership_type
  end

  test "editors cannot delete memberships or payments" do
    payment = payments(:recent_payment)
    sign_in_as(@editor)

    get admin_membership_path(@membership)
    assert_select "button", text: /Delete/, count: 0

    assert_no_difference [ "Membership.count", "Payment.count" ] do
      delete admin_membership_path(@membership)
      assert_redirected_to root_path
      delete admin_membership_payment_path(@membership, payment)
      assert_redirected_to root_path
    end
  end

  test "owners see the delete buttons" do
    sign_in_as(@owner)
    get admin_membership_path(@membership)
    assert_select "button", text: "Delete Membership"
  end

  test "owner can access index" do
    sign_in_as(@owner)
    get admin_memberships_path
    assert_response :success
  end

  test "index shows all memberships" do
    sign_in_as(@owner)
    get admin_memberships_path
    assert_response :success
    assert_includes response.body, memberships(:active_membership).user.email_address
  end

  test "show displays membership details" do
    sign_in_as(@owner)
    get admin_membership_path(@membership)
    assert_response :success
  end

  test "new renders form for creating membership" do
    sign_in_as(@owner)
    get new_admin_membership_path
    assert_response :success
  end

  test "create adds new membership" do
    sign_in_as(@owner)
    assert_difference "Membership.count" do
      post admin_memberships_path, params: {
        membership: {
          user_id: @viewer.id,
          membership_type: "full",
          starts_on: Date.current
        }
      }
    end
    assert_redirected_to admin_membership_path(Membership.last)
  end

  test "edit renders form for updating membership" do
    sign_in_as(@owner)
    get edit_admin_membership_path(@membership)
    assert_response :success
  end

  test "update modifies membership" do
    sign_in_as(@owner)
    patch admin_membership_path(@membership), params: {
      membership: { notes: "Updated notes" }
    }
    assert_redirected_to admin_membership_path(@membership)
    @membership.reload
    assert_equal "Updated notes", @membership.notes
  end

  test "destroy removes membership" do
    sign_in_as(@owner)
    assert_difference "Membership.count", -1 do
      delete admin_membership_path(@membership)
    end
    assert_redirected_to admin_memberships_path
  end

  # Search
  test "index filters by email search query" do
    sign_in_as(@owner)
    get admin_memberships_path, params: { q: "owner@example" }
    assert_response :success
    assert_includes response.body, "owner@example.com"
    refute_includes response.body, "editor@example.com"
  end

  test "index shows all memberships when no search query" do
    sign_in_as(@owner)
    get admin_memberships_path
    assert_response :success
    assert_includes response.body, "owner@example.com"
    assert_includes response.body, "editor@example.com"
  end

  # Payment status filters
  def create_membership(type:, expires_on:, email:)
    user = User.create!(email_address: email, password: "password", approved: true)
    Membership.create!(user: user, membership_type: type, starts_on: 1.year.ago.to_date, expires_on: expires_on)
  end

  test "index filters to paid memberships" do
    sign_in_as(@owner)
    get admin_memberships_path, params: { status: "paid" }
    assert_response :success
    assert_select "tbody div", text: "owner@example.com"
    assert_select "tbody div", { count: 0, text: "editor@example.com" }
  end

  test "index filters to lapsed memberships" do
    sign_in_as(@owner)
    get admin_memberships_path, params: { status: "lapsed" }
    assert_response :success
    assert_select "tbody div", text: "editor@example.com"
    assert_select "tbody div", { count: 0, text: "owner@example.com" }
  end

  test "index filters to unpaid memberships" do
    sign_in_as(@owner)
    create_membership(type: :full, expires_on: nil, email: "never-paid@example.com")
    get admin_memberships_path, params: { status: "unpaid" }
    assert_select "tbody div", text: "never-paid@example.com"
    assert_select "tbody div", { count: 0, text: "owner@example.com" }
  end

  test "index filters to memberships renewing soon" do
    sign_in_as(@owner)
    create_membership(type: :full, expires_on: 10.days.from_now.to_date, email: "renew-soon@example.com")
    get admin_memberships_path, params: { status: "renewing" }
    assert_select "tbody div", text: "renew-soon@example.com"
    assert_select "tbody div", { count: 0, text: "owner@example.com" }
  end

  test "index filters to associates with no fee" do
    sign_in_as(@owner)
    create_membership(type: :associate, expires_on: nil, email: "associate@example.com")
    get admin_memberships_path, params: { status: "no_fee" }
    assert_select "tbody div", text: "associate@example.com"
    assert_select "tbody div", { count: 0, text: "owner@example.com" }
  end

  test "index shows a count for each payment status" do
    sign_in_as(@owner)
    create_membership(type: :full, expires_on: nil, email: "never-paid@example.com")
    get admin_memberships_path
    assert_select "a[data-status-count=paid]", text: /#{Membership.paid.count}/
    assert_select "a[data-status-count=lapsed]", text: /#{Membership.lapsed.count}/
    assert_select "a[data-status-count=unpaid]", text: /1/
  end

  test "index searches by member name as well as email" do
    sign_in_as(@owner)
    get admin_memberships_path, params: { q: "Admin User" }
    assert_select "tbody div", text: "owner@example.com"
    assert_select "tbody div", { count: 0, text: "editor@example.com" }
  end

  test "mark paid records a payment and renews the membership" do
    sign_in_as(@owner)
    membership = memberships(:expired_membership)
    assert_difference "Payment.count", 1 do
      patch toggle_paid_admin_membership_path(membership), params: { payment_method: "cash", status: "lapsed" }
    end
    assert_redirected_to admin_memberships_path(status: "lapsed")
    assert_equal :paid, membership.reload.payment_status
    assert membership.payments.last.cash?
  end

  test "mark paid rejects payment methods other than cash, bank transfer or other" do
    sign_in_as(@owner)
    membership = memberships(:expired_membership)
    assert_no_difference "Payment.count" do
      patch toggle_paid_admin_membership_path(membership), params: { payment_method: "sumup" }
    end
    assert_equal :lapsed, membership.reload.payment_status
  end

  test "toggling a paid membership marks it unpaid" do
    sign_in_as(@owner)
    patch toggle_paid_admin_membership_path(@membership)
    assert_equal :unpaid, @membership.reload.payment_status
  end

  test "associate memberships cannot be toggled" do
    sign_in_as(@owner)
    associate = create_membership(type: :associate, expires_on: nil, email: "assoc2@example.com")
    patch toggle_paid_admin_membership_path(associate)
    assert_redirected_to admin_memberships_path
    assert_equal :no_fee, associate.reload.payment_status
  end

  test "editors can mark a membership paid" do
    sign_in_as(@editor)
    unpaid = Membership.create!(user: @viewer, membership_type: :full, starts_on: Date.current)
    patch toggle_paid_admin_membership_path(unpaid), params: { payment_method: "cash" }
    assert_equal :paid, unpaid.reload.payment_status
  end

  test "viewers cannot toggle paid" do
    sign_in_as(@viewer)
    patch toggle_paid_admin_membership_path(@membership)
    assert_redirected_to root_path
  end

  # Pagination
  test "index paginates 20 per page and keeps filters in the page links" do
    sign_in_as(@owner)
    21.times { Membership.create!(user: @owner, membership_type: :full, starts_on: Date.current) }

    get admin_memberships_path(type: "full")
    assert_response :success
    assert_select "tbody tr", 20
    assert_select "nav a[href*='page=2'][href*='type=full']"

    get admin_memberships_path(type: "full", page: 2)
    assert_response :success
    assert_select "tbody tr", Membership.full.count - 20
  end

  # CSV export
  test "exports the filtered memberships as CSV" do
    sign_in_as(@owner)
    get admin_memberships_path(format: :csv, status: "lapsed")

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match(/attachment; filename="memberships-lapsed-#{Date.current}\.csv"/, response.headers["Content-Disposition"])

    rows = CSV.parse(response.body, headers: true)
    assert_equal [ "Name", "Email", "Type", "Payment status", "Started", "Paid until", "Last payment", "Last payment method", "Notes" ], rows.headers
    assert_equal 1, rows.size
    expired = memberships(:expired_membership)
    last_payment = payments(:old_payment)
    assert_equal [ "Editor User", "editor@example.com", "Concession", "Lapsed", expired.starts_on.iso8601, expired.expires_on.iso8601,
                   last_payment.paid_on.iso8601, "Bank transfer", "Expired concession membership" ], rows.first.fields
  end

  test "export applies search, type and paid until filters together" do
    sign_in_as(@owner)
    get admin_memberships_path(format: :csv, q: "example.com", type: "full", period: "this_year")

    emails = CSV.parse(response.body, headers: true).map { |row| row["Email"] }
    expected = Membership.full.where(expires_on: Date.current.all_year).map { |m| m.user.email_address }
    assert_equal expected.sort, emails.sort
  end

  test "export gives the last payment and how it was made" do
    create_membership(type: :full, expires_on: nil, email: "payer@example.org").record_payment!(payment_method: "bank_transfer", paid_on: Date.new(2026, 3, 5))
    create_membership(type: :full, expires_on: nil, email: "never-paid@example.org")
    sign_in_as(@owner)
    get admin_memberships_path(format: :csv, q: "example.org")

    rows = CSV.parse(response.body, headers: true).index_by { |row| row["Email"] }
    assert_equal [ "2026-03-05", "Bank transfer" ], rows["payer@example.org"].fields.values_at(6, 7)
    assert_equal [ nil, nil ], rows["never-paid@example.org"].fields.values_at(6, 7)
  end

  test "export is not paginated" do
    sign_in_as(@owner)
    21.times { |i| create_membership(type: :full, expires_on: nil, email: "bulk#{i}@example.org") }

    get admin_memberships_path(format: :csv, status: "unpaid")
    assert_equal 21, CSV.parse(response.body, headers: true).size
  end

  test "export neutralises values a spreadsheet would run as a formula" do
    @membership.update!(notes: "=HYPERLINK(\"http://evil.example\")")
    @owner.profile.update!(name: "+cmd")
    sign_in_as(@owner)
    get admin_memberships_path(format: :csv, q: "owner@example")

    row = CSV.parse(response.body, headers: true).first
    assert_equal "'+cmd", row["Name"]
    assert row["Notes"].start_with?("'=")
  end

  test "editors can export" do
    sign_in_as(@editor)
    get admin_memberships_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
  end

  test "viewers cannot export" do
    sign_in_as(@viewer)
    get admin_memberships_path(format: :csv)
    assert_redirected_to root_path
  end

  test "export link keeps the current filters but not the page" do
    sign_in_as(@owner)
    get admin_memberships_path(status: "paid", type: "full", q: "example", period: "this_year", page: 1)
    assert_select "a[href*='.csv'][href*='status=paid'][href*='type=full'][href*='q=example'][href*='period=this_year']:not([href*='page='])", text: /Export/
  end

  # Payment management
  test "can add payment to membership" do
    sign_in_as(@owner)
    assert_difference "Payment.count" do
      post admin_membership_payments_path(@membership), params: {
        payment: {
          amount_euro: "20",
          paid_on: Date.current,
          payment_method: "cash",
          purpose: "membership",
          description: "Annual membership fee"
        }
      }
    end
    assert_redirected_to admin_membership_path(@membership)
  end

  test "can delete payment" do
    sign_in_as(@owner)
    payment = payments(:recent_payment)
    assert_difference "Payment.count", -1 do
      delete admin_membership_payment_path(@membership, payment)
    end
    assert_redirected_to admin_membership_path(@membership)
  end

  # Date filters: when a membership is paid until
  def membership_expiring(on, user: @owner, type: :full)
    Membership.create!(user: user, membership_type: type, starts_on: 3.years.ago.to_date, expires_on: on)
  end

  test "paid until range includes the first and last day" do
    sign_in_as(@owner)
    membership_expiring(Date.new(2040, 12, 1), user: users(:viewer))
    membership_expiring(Date.new(2040, 12, 31), user: users(:editor))
    membership_expiring(Date.new(2040, 11, 30))
    membership_expiring(Date.new(2041, 1, 1))

    get admin_memberships_path(from: "2040-12-01", to: "2040-12-31")

    assert_select "tbody tr", 2
    assert_select "tbody td", text: /01 Dec 2040/
    assert_select "tbody td", text: /31 Dec 2040/
  end

  test "paid until with only a from date" do
    sign_in_as(@owner)
    membership_expiring(Date.new(2040, 12, 31), user: users(:viewer))

    get admin_memberships_path(from: "2040-12-01")
    assert_select "tbody td", text: /31 Dec 2040/
    assert_select "tbody td", text: /#{Regexp.escape(memberships(:expired_membership).expires_on.strftime('%d %b %Y'))}/, count: 0
  end

  test "paid until with only a to date" do
    sign_in_as(@owner)
    get admin_memberships_path(to: Date.current.iso8601)

    assert_select "tbody div", text: "editor@example.com"
    assert_select "tbody div", { count: 0, text: "owner@example.com" }
  end

  test "period preset for the year memberships run to" do
    sign_in_as(@owner)
    this_year = membership_expiring(Date.current.end_of_year, user: users(:viewer))
    next_year = membership_expiring(Date.current.end_of_year + 1.year, user: users(:editor))

    get admin_memberships_path(period: "this_year", q: "viewer@")

    assert_select "tbody td", text: /#{this_year.expires_on.strftime('%d %b %Y')}/
    assert_select "tbody td", text: /#{next_year.expires_on.strftime('%d %b %Y')}/, count: 0
  end

  test "date range combines with status and type" do
    sign_in_as(@owner)
    membership_expiring(Date.new(2040, 12, 31), user: users(:viewer), type: :youth)
    membership_expiring(Date.new(2040, 12, 31), user: users(:editor), type: :full)

    get admin_memberships_path(from: "2040-12-01", to: "2040-12-31", type: "youth", status: "paid")

    assert_select "tbody tr", 1
    assert_select "tbody div", text: "viewer@example.com"
  end

  test "tabs, search and the date form keep the date range" do
    sign_in_as(@owner)
    get admin_memberships_path(from: "2040-12-01", to: "2040-12-31", status: "paid", q: "x")

    assert_select "a[data-status-count='lapsed'][href*='from=2040-12-01'][href*='to=2040-12-31'][href*='q=x']"
    assert_select "input[type=hidden][name=from][value='2040-12-01']"
    assert_select "input[type=hidden][name=to][value='2040-12-31']"
    assert_select "input[type=date][name=from][value='2040-12-01']"
    assert_select "input[type=hidden][name=status][value=paid]"
  end

  test "marking paid returns to the same date range" do
    sign_in_as(@owner)
    unpaid = Membership.create!(user: @viewer, membership_type: :full, starts_on: Date.current)

    patch toggle_paid_admin_membership_path(unpaid), params: { payment_method: "cash", from: "2040-12-01", period: "" }
    assert_redirected_to admin_memberships_path(from: "2040-12-01")
  end

  # Show page
  test "show says a membership with no payment is unpaid, not active" do
    sign_in_as(@owner)
    unpaid = Membership.create!(user: @viewer, membership_type: :full, starts_on: Date.current)
    get admin_membership_path(unpaid)

    assert_select "[data-payment-status]", text: /Unpaid/
    assert_select "dd", text: "Never", count: 0
    assert_select "dd", text: /Active/, count: 0
  end

  test "show says when a lapsed membership ran out and a paid one is paid until" do
    sign_in_as(@owner)
    get admin_membership_path(memberships(:expired_membership))
    assert_select "[data-payment-status]", text: /Lapsed/

    get admin_membership_path(@membership)
    assert_select "[data-payment-status]", text: /Paid/
    assert_select "dt", text: "Paid until"
  end

  test "show says an associate has no fee" do
    sign_in_as(@owner)
    associate = Membership.create!(user: @viewer, membership_type: :associate, starts_on: Date.current)
    get admin_membership_path(associate)
    assert_select "[data-payment-status]", text: /No fee/
  end

  test "record payment form takes euros and starts at the fee for the membership type" do
    sign_in_as(@owner)
    get admin_membership_path(@membership)

    assert_select "input[name='payment[amount_euro]'][value='20.00']"
    assert_select "input[name='payment[amount_cents]']", count: 0
  end

  test "show lists payments with the member's name" do
    sign_in_as(@owner)
    get admin_membership_path(@membership)
    assert_includes response.body, "Admin User"
  end
end
