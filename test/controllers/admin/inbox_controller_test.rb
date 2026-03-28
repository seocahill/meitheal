require "test_helper"

class Admin::InboxControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    sign_in_as(@owner)

    # Stub ZohoMailService so show action doesn't hit real API for attachments
    @original_zoho_new = ZohoMailService.method(:new)
    stub_zoho = Object.new
    stub_zoho.define_singleton_method(:configured?) { false }
    ZohoMailService.define_singleton_method(:new) { stub_zoho }

    @email = CachedEmail.create!(
      zoho_message_id: "msg_test_001",
      zoho_folder_id: "folder_inbox",
      from_address: "alice@example.com",
      subject: "Exhibition Update",
      summary: "Details about the upcoming exhibition",
      body: "<p>Full email body here</p>",
      received_at: 2.hours.ago,
      status: :unread
    )
    @archived_email = CachedEmail.create!(
      zoho_message_id: "msg_test_002",
      zoho_folder_id: "folder_inbox",
      from_address: "bob@example.com",
      subject: "Old Announcement",
      summary: "Previously archived",
      body: "<p>Archived content</p>",
      received_at: 1.day.ago,
      status: :archived
    )
  end

  teardown do
    ZohoMailService.define_singleton_method(:new, @original_zoho_new)
  end

  # Access control

  test "requires owner role" do
    sign_out
    sign_in_as(users(:editor))
    get admin_inbox_index_path
    assert_redirected_to root_path
  end

  # Index

  test "index shows visible emails" do
    get admin_inbox_index_path
    assert_response :success
    assert_includes response.body, "Exhibition Update"
    assert_not_includes response.body, "Old Announcement"
  end

  test "index shows archived emails when filtered" do
    get admin_inbox_index_path(show_archived: true)
    assert_response :success
    assert_includes response.body, "Old Announcement"
    assert_not_includes response.body, "Exhibition Update"
  end

  test "index paginates results" do
    6.times do |i|
      CachedEmail.create!(
        zoho_message_id: "msg_page_#{i}",
        zoho_folder_id: "folder_inbox",
        from_address: "sender#{i}@example.com",
        subject: "Email #{i}",
        received_at: i.hours.ago
      )
    end
    get admin_inbox_index_path
    assert_response :success
    assert_select "a", text: "Next"
  end

  # Show

  test "show displays cached email" do
    get admin_inbox_path(@email)
    assert_response :success
    assert_includes response.body, "Exhibition Update"
    assert_includes response.body, "alice@example.com"
    assert_includes response.body, "Full email body here"
  end

  test "show marks email as read" do
    assert @email.unread?
    get admin_inbox_path(@email)
    assert @email.reload.read?
  end

  # Archive / Unarchive

  test "archive changes email status to archived" do
    post archive_admin_inbox_path(@email)
    assert @email.reload.archived?
    assert_redirected_to admin_inbox_index_path
  end

  test "unarchive changes email status to read" do
    post unarchive_admin_inbox_path(@archived_email)
    assert @archived_email.reload.read?
    assert_redirected_to admin_inbox_index_path(show_archived: true)
  end

  test "batch archive archives multiple emails" do
    email2 = CachedEmail.create!(
      zoho_message_id: "msg_batch_001",
      zoho_folder_id: "folder_inbox",
      from_address: "carol@example.com",
      subject: "Batch Test",
      received_at: 1.hour.ago
    )
    post batch_archive_admin_inbox_index_path, params: { ids: [ @email.id, email2.id ] }
    assert @email.reload.archived?
    assert email2.reload.archived?
    assert_redirected_to admin_inbox_index_path
  end

  # Create actions

  test "create_todo creates a todo from cached email" do
    assert_difference "AdminTodo.count", 1 do
      post create_todo_admin_inbox_path(@email)
    end
    todo = AdminTodo.last
    assert_includes todo.title, "Exhibition Update"
    assert_redirected_to admin_inbox_path(@email)
  end

  test "create_newsletter creates a newsletter from cached email" do
    assert_difference "Newsletter.count", 1 do
      post create_newsletter_admin_inbox_path(@email)
    end
    newsletter = Newsletter.last
    assert_equal "Exhibition Update", newsletter.subject
    assert_redirected_to edit_newsletter_path(newsletter)
  end

  test "create_funding creates a funding opportunity from cached email" do
    assert_difference "FundingOpportunity.count", 1 do
      post create_funding_admin_inbox_path(@email)
    end
    funding = FundingOpportunity.last
    assert_equal "Exhibition Update", funding.title
    assert_redirected_to edit_funding_opportunity_path(funding)
  end
end
