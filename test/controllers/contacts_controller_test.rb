require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get contact_url
    assert_response :success
    assert_match "Contact us", response.body
  end

  test "should send contact message" do
    assert_enqueued_emails 1 do
      post contact_url, params: { email: "visitor@example.com", message: "Hello, I have a question." }
    end
    assert_redirected_to contact_url
    follow_redirect!
    assert_match "Thanks for your message", response.body
  end

  test "should reject blank email" do
    post contact_url, params: { email: "", message: "Hello" }
    assert_response :unprocessable_entity
    assert_match "Please fill in both fields", response.body
  end

  test "should reject blank message" do
    post contact_url, params: { email: "visitor@example.com", message: "" }
    assert_response :unprocessable_entity
    assert_match "Please fill in both fields", response.body
  end
end
