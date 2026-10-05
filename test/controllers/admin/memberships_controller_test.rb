require "test_helper"

class Admin::MembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @membership = memberships(:active_membership)
  end

  # Access control
  test "index requires owner role" do
    sign_in_as(@editor)
    get admin_memberships_path
    assert_redirected_to root_path
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

  test "toggle requires owner" do
    sign_in_as(@editor)
    patch toggle_paid_admin_membership_path(@membership)
    assert_redirected_to root_path
  end

  # Pagination
  test "index paginates 10 per page and shows navigation" do
    sign_in_as(@owner)
    11.times do |i|
      Membership.create!(user: @owner, membership_type: :full, starts_on: Date.current)
    end

    get admin_memberships_path
    assert_response :success
    assert_includes response.body, "Next"
    refute_includes response.body, "Previous"

    get admin_memberships_path, params: { page: 2 }
    assert_response :success
    assert_includes response.body, "Previous"
  end

  # Payment management
  test "can add payment to membership" do
    sign_in_as(@owner)
    assert_difference "Payment.count" do
      post admin_membership_payments_path(@membership), params: {
        payment: {
          amount_cents: 2000,
          paid_on: Date.current,
          payment_method: "cash",
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
end
