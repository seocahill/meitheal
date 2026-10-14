require "test_helper"

# The public newsletter page for anyone, member or not. Signing up goes straight
# to the Brevo mailing list and creates nothing on the platform.
class NewsletterSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  class FakeBrevo
    attr_reader :added

    def initialize(campaigns: [], add_error: nil, list_error: nil)
      @campaigns = campaigns
      @add_error = add_error
      @list_error = list_error
      @added = []
    end

    def sent_campaigns
      raise @list_error if @list_error

      @campaigns
    end

    def add_contact(email, name: nil)
      raise @add_error if @add_error

      @added << [ email, name ]
    end
  end

  setup do
    @original_brevo_new = BrevoService.method(:new)
    Newsletter.delete_all
    use_brevo(FakeBrevo.new)
  end

  teardown do
    BrevoService.define_singleton_method(:new, @original_brevo_new)
  end

  def use_brevo(fake)
    @brevo = fake
    BrevoService.define_singleton_method(:new) { |*| fake }
  end

  # The page itself
  test "the page is public and shows the signup form" do
    get newsletter_page_path

    assert_response :success
    assert_select "h2", text: "Subscribe"
    assert_select "form[action='#{newsletter_subscribe_path}']"
    assert_includes response.body, "Subscribe"
  end

  test "the page shows the QR code" do
    get newsletter_page_path
    assert_select "img[src='#{newsletter_qr_code_path}']"
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

  # Past issues
  test "past issues list Brevo newsletters with a link to each" do
    use_brevo(FakeBrevo.new(campaigns: [
      { id: 51, subject: "October Newsletter", sentDate: "2026-10-02T12:07:22.000+02:00", shareLink: "http://sh1.sendinblue.com/nmo49686gc.html" }
    ]))
    get newsletter_page_path

    assert_select "h2", text: "Past Issues"
    assert_select "a[href='http://sh1.sendinblue.com/nmo49686gc.html'][target=_blank][rel~=noopener]", text: "October Newsletter"
    assert_includes response.body, "2 October 2026"
  end

  test "past issues link to our own archived copy where there is one" do
    copy = Newsletter.create!(subject: "December Newsletter", content: "<p>Hi</p>", status: :sent,
                              sent_at: Time.zone.local(2025, 12, 26, 15, 0), brevo_campaign_id: 28)
    use_brevo(FakeBrevo.new(campaigns: [
      { id: 28, subject: "December Newsletter", sentDate: "2025-12-26T15:04:25.000+01:00", shareLink: "http://sh1.sendinblue.com/old.html" }
    ]))
    get newsletter_page_path

    assert_select "a[href='#{newsletter_path(copy)}']", text: "December Newsletter"
    assert_select "a[href='http://sh1.sendinblue.com/old.html']", count: 0
  end

  test "past issues still list archived newsletters when Brevo is down" do
    copy = Newsletter.create!(subject: "December Newsletter", content: "<p>Hi</p>", status: :sent,
                              sent_at: Time.zone.local(2025, 12, 26, 15, 0), brevo_campaign_id: 28)
    use_brevo(FakeBrevo.new(list_error: BrevoService::ApiError.new("down")))
    get newsletter_page_path

    assert_response :success
    assert_select "a[href='#{newsletter_path(copy)}']", text: "December Newsletter"
  end

  test "past issues are hidden when there are none" do
    get newsletter_page_path

    assert_response :success
    assert_select "h2", text: "Past Issues", count: 0
  end

  # Signing up
  test "signing up adds the email straight to Brevo" do
    post newsletter_subscribe_path, params: { email: "newsubscriber@example.com" }

    assert_equal [ [ "newsubscriber@example.com", nil ] ], @brevo.added
    assert_redirected_to newsletter_page_path
    assert_equal "Thanks for subscribing! You'll receive our next newsletter.", flash[:notice]
  end

  test "signing up creates no user, profile or membership on the platform" do
    assert_no_difference [ "User.count", "Profile.count", "Membership.count" ] do
      post newsletter_subscribe_path, params: { email: "newsubscriber@example.com" }
    end
  end

  test "signing up with a member's email changes nothing on the platform" do
    member = users(:viewer)

    assert_no_difference [ "User.count", "Membership.count" ] do
      post newsletter_subscribe_path, params: { email: member.email_address }
    end
    assert_equal [ [ member.email_address, nil ] ], @brevo.added
  end

  test "the email is trimmed and lowercased before it goes to Brevo" do
    post newsletter_subscribe_path, params: { email: "  UPPER@EXAMPLE.COM " }
    assert_equal "upper@example.com", @brevo.added.first.first
  end

  test "a blank email re-renders the form with an error and does not call Brevo" do
    post newsletter_subscribe_path, params: { email: "" }

    assert_response :unprocessable_entity
    assert_includes response.body, "Please enter your email address."
    assert_empty @brevo.added
  end

  test "an invalid email re-renders the form with an error and does not call Brevo" do
    post newsletter_subscribe_path, params: { email: "not-an-email" }

    assert_response :unprocessable_entity
    assert_includes response.body, "That doesn&#39;t look like an email address."
    assert_empty @brevo.added
  end

  test "when Brevo refuses the signup the visitor is told and nothing is claimed" do
    use_brevo(FakeBrevo.new(add_error: BrevoService::ApiError.new("Invalid email")))
    post newsletter_subscribe_path, params: { email: "fail@example.com" }

    assert_response :unprocessable_entity
    assert_includes response.body, "Sorry, we couldn&#39;t sign you up just now. Please try again later."
    assert_nil flash[:notice]
  end

  test "when Brevo is not configured the visitor is told and nothing is claimed" do
    use_brevo(FakeBrevo.new(add_error: BrevoService::ConfigurationError.new("Missing configuration")))
    post newsletter_subscribe_path, params: { email: "fail@example.com" }

    assert_response :unprocessable_entity
    assert_includes response.body, "Sorry, we couldn&#39;t sign you up just now."
  end
end
