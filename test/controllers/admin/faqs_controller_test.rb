require "test_helper"

class Admin::FaqsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @faq = faqs(:one)
  end

  test "should get index when owner" do
    sign_in_as(@owner)
    get admin_faqs_url
    assert_response :success
  end

  test "should get new when owner" do
    sign_in_as(@owner)
    get new_admin_faq_url
    assert_response :success
  end

  test "should create faq when owner" do
    sign_in_as(@owner)
    assert_difference("Faq.count") do
      post admin_faqs_url, params: { faq: { question: "New Question?", answer: "New Answer" } }
    end
    assert_redirected_to admin_faqs_url
  end

  test "should get edit when owner" do
    sign_in_as(@owner)
    get edit_admin_faq_url(@faq)
    assert_response :success
  end

  test "should update faq when owner" do
    sign_in_as(@owner)
    patch admin_faq_url(@faq), params: { faq: { question: "Updated Question?" } }
    assert_redirected_to admin_faqs_url
  end

  test "should destroy faq when owner" do
    sign_in_as(@owner)
    assert_difference("Faq.count", -1) do
      delete admin_faq_url(@faq)
    end
    assert_redirected_to admin_faqs_url
  end
end
