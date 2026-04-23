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

  # Status filter
  test "index filters to active memberships" do
    sign_in_as(@owner)
    get admin_memberships_path, params: { status: "active" }
    assert_response :success
    assert_select "tbody div", text: "owner@example.com"
    assert_select "tbody div", { count: 0, text: "editor@example.com" }
  end

  test "index filters to expired memberships" do
    sign_in_as(@owner)
    get admin_memberships_path, params: { status: "expired" }
    assert_response :success
    assert_select "tbody div", text: "editor@example.com"
    assert_select "tbody div", { count: 0, text: "owner@example.com" }
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
