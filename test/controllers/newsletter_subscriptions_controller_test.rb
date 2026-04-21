require "test_helper"

class NewsletterSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_brevo_new = BrevoService.method(:new)
    stub_brevo = Object.new
    stub_brevo.define_singleton_method(:configured?) { false }
    BrevoService.define_singleton_method(:new) { stub_brevo }
  end

  teardown do
    BrevoService.define_singleton_method(:new, @original_brevo_new)
  end

  test "qr_code serves SVG with correct content type" do
    get newsletter_qr_code_path
    assert_response :success
    assert_equal "image/svg+xml", response.content_type
  end

  test "qr_code response includes SVG markup" do
    get newsletter_qr_code_path
    assert_includes response.body, "<svg"
  end

  test "qr_code is publicly accessible" do
    get newsletter_qr_code_path
    assert_response :success
  end

  test "new shows signup form and archive" do
    get newsletter_page_path
    assert_response :success
    assert_includes response.body, "Subscribe"
  end

  test "new shows sent newsletters in archive" do
    sent = newsletters(:sent_newsletter)
    get newsletter_page_path
    assert_includes response.body, sent.subject
  end

  test "new does not show draft newsletters in archive" do
    draft = newsletters(:monthly_update)
    get newsletter_page_path
    refute_includes response.body, draft.subject
  end

  test "create with new email creates user and associate membership" do
    assert_difference [ "User.count", "Membership.count" ], 1 do
      post newsletter_subscribe_path, params: { email: "newsubscriber@example.com" }
    end

    user = User.find_by(email_address: "newsubscriber@example.com")
    assert user.approved?
    assert user.viewer?
    assert user.memberships.last.associate?
    assert_redirected_to newsletter_page_path
  end

  test "create with new email creates profile" do
    post newsletter_subscribe_path, params: { email: "newsubscriber@example.com" }
    user = User.find_by(email_address: "newsubscriber@example.com")
    assert user.profile.present?
  end

  test "create with existing user does not create duplicate user" do
    existing = users(:viewer)

    assert_no_difference "User.count" do
      post newsletter_subscribe_path, params: { email: existing.email_address }
    end

    assert_redirected_to newsletter_page_path
  end

  test "create with existing user ensures associate membership" do
    existing = users(:editor)
    # Editor has an expired membership - should get a new associate one
    assert_difference "Membership.count", 1 do
      post newsletter_subscribe_path, params: { email: existing.email_address }
    end

    assert existing.memberships.active.exists?
  end

  test "create with existing active member does not create duplicate membership" do
    existing = users(:owner)
    # Owner already has an active membership
    assert_no_difference "Membership.count" do
      post newsletter_subscribe_path, params: { email: existing.email_address }
    end
  end

  test "create shows same success message for new and existing emails" do
    # New email
    post newsletter_subscribe_path, params: { email: "brand-new@example.com" }
    assert_redirected_to newsletter_page_path
    new_notice = flash[:notice]

    # Existing email
    post newsletter_subscribe_path, params: { email: users(:viewer).email_address }
    assert_redirected_to newsletter_page_path
    existing_notice = flash[:notice]

    assert_equal new_notice, existing_notice
  end

  test "create with blank email re-renders form with error" do
    assert_no_difference "User.count" do
      post newsletter_subscribe_path, params: { email: "" }
    end
    assert_response :unprocessable_entity
  end

  test "create normalizes email to lowercase" do
    post newsletter_subscribe_path, params: { email: "UPPER@EXAMPLE.COM" }
    assert User.find_by(email_address: "upper@example.com")
  end

  test "create syncs to brevo best-effort" do
    # Brevo sync failures should not break signup
    original = BrevoService.method(:new)
    error_service = Object.new
    error_service.define_singleton_method(:configured?) { true }
    error_service.define_singleton_method(:add_contact) { |*| raise BrevoService::ApiError, "fail" }
    BrevoService.define_singleton_method(:new) { error_service }

    assert_difference "User.count", 1 do
      post newsletter_subscribe_path, params: { email: "brevo-fail@example.com" }
    end

    assert_redirected_to newsletter_page_path
  ensure
    BrevoService.define_singleton_method(:new, original)
  end
end
