require "test_helper"

class FlipperUiTest < ActionDispatch::IntegrationTest
  test "signed-out visitor gets a 404 at /flipper" do
    get "/flipper"
    assert_response :not_found
  end

  test "viewer gets a 404 at /flipper" do
    sign_in_as(users(:viewer))

    get "/flipper"
    assert_response :not_found
  end

  test "editor gets a 404 at /flipper" do
    sign_in_as(users(:editor))

    get "/flipper"
    assert_response :not_found
  end

  test "owner can open /flipper" do
    sign_in_as(users(:owner))

    get "/flipper/features"
    assert_response :success
  end

  test "editor cannot change a flag" do
    sign_in_as(users(:editor))

    post "/flipper/features/f1_example/boolean"
    assert_response :not_found
    refute Flipper.enabled?(:f1_example)
  end
end
