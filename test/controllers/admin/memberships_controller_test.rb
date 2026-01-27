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
          membership_type: "standard",
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

  # Payment management
  test "can add payment to membership" do
    sign_in_as(@owner)
    assert_difference "Payment.count" do
      post admin_membership_payments_path(@membership), params: {
        payment: {
          amount_cents: 2000,
          paid_on: Date.current,
          payment_method: "cash"
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
