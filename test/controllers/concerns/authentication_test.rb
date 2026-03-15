require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  # Use faq_path because FaqsController has allow_unauthenticated_access
  # without any explicit authenticated? calls in its actions
  test "session is restored on unauthenticated routes when user is signed in" do
    sign_in_as(users(:viewer))
    get faq_path
    assert_response :success
    assert_not_nil Current.session
    assert_equal users(:viewer), Current.user
  end

  test "session is nil on unauthenticated routes when user is not signed in" do
    get faq_path
    assert_response :success
    assert_nil Current.session
  end

  test "unauthenticated routes remain accessible without a session" do
    get faq_path
    assert_response :success
  end
end
