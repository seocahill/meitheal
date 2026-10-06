require "test_helper"

# The public copy of each newsletter sent through Brevo, kept so old links keep working.
class NewslettersControllerTest < ActionDispatch::IntegrationTest
  test "anyone can read a sent newsletter without signing in" do
    newsletter = newsletters(:sent_newsletter)
    get newsletter_path(newsletter)

    assert_response :success
    assert_select "h1", text: newsletter.subject
    assert_includes response.body, "December was a great month"
    assert_includes response.body, newsletter.sent_at.strftime("%B %d, %Y")
  end

  test "a sent newsletter links back to the newsletter page" do
    get newsletter_path(newsletters(:sent_newsletter))
    assert_select "a[href='#{newsletter_page_path}']"
  end

  test "drafts are not public" do
    get newsletter_path(newsletters(:monthly_update))

    assert_redirected_to newsletter_page_path
    assert_equal "Newsletter not found.", flash[:alert]
  end

  test "drafts are not shown to signed-in members either" do
    sign_in_as(users(:viewer))
    get newsletter_path(newsletters(:monthly_update))
    assert_redirected_to newsletter_page_path
  end

  test "unknown newsletters redirect to the newsletter page" do
    get newsletter_path(id: 999_999)
    assert_redirected_to newsletter_page_path
  end

  test "there is no list, editor or other way in" do
    sign_in_as(users(:owner))
    get "/newsletters"
    assert_response :not_found
  end
end
