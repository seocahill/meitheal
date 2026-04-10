require "test_helper"

class SyncBrevoContactsJobTest < ActiveJob::TestCase
  setup do
    # Brevo contacts use symbol keys — the gem deserializes with symbolize_names: true
    @brevo_contacts = [
      { email: "alice@example.com", attributes: { FIRSTNAME: "Alice" } },
      { email: "bob@example.com", attributes: { FIRSTNAME: "Bob" } }
    ]

    @stub_brevo = build_stub_brevo

    # Create local users (some overlap with Brevo, some not)
    @local_user = User.create!(
      email_address: "charlie@example.com",
      password: "password123",
      password_confirmation: "password123",
      approved: true
    )
    @existing_synced_user = User.create!(
      email_address: "alice@example.com",
      password: "password123",
      password_confirmation: "password123",
      approved: true
    )
    @unapproved_user = User.create!(
      email_address: "unapproved@example.com",
      password: "password123",
      password_confirmation: "password123",
      approved: false
    )
  end

  test "syncs local users to Brevo" do
    added_contacts = []
    @stub_brevo.define_singleton_method(:add_contact) do |email, name:|
      added_contacts << { email: email, name: name }
    end

    SyncBrevoContactsJob.perform_now(brevo_service: @stub_brevo)

    # Charlie should be added to Brevo (local but not in Brevo)
    assert added_contacts.any? { |c| c[:email] == "charlie@example.com" }
    # Alice should not be added (already in Brevo)
    refute added_contacts.any? { |c| c[:email] == "alice@example.com" }
    # Unapproved should not be synced
    refute added_contacts.any? { |c| c[:email] == "unapproved@example.com" }
  end

  test "syncs Brevo contacts to local users" do
    SyncBrevoContactsJob.perform_now(brevo_service: @stub_brevo)

    # Bob should be created locally (in Brevo but not local)
    bob = User.find_by(email_address: "bob@example.com")
    assert bob
    assert bob.approved?
    # Alice should not be duplicated (already exists locally)
    assert_equal 1, User.where(email_address: "alice@example.com").count
  end

  test "does nothing when Brevo is not configured" do
    @stub_brevo.define_singleton_method(:configured?) { false }

    assert_no_difference "User.count" do
      SyncBrevoContactsJob.perform_now(brevo_service: @stub_brevo)
    end
  end

  test "handles Brevo API errors gracefully" do
    @stub_brevo.define_singleton_method(:list_contacts) do |limit:, offset:|
      raise BrevoService::ApiError, "Rate limited"
    end

    assert_nothing_raised do
      SyncBrevoContactsJob.perform_now(brevo_service: @stub_brevo)
    end
  end

  test "syncs contacts case-insensitively" do
    # Brevo has uppercase, local has lowercase
    @brevo_contacts = [ { email: "DAVID@EXAMPLE.COM", attributes: {} } ]
    User.create!(
      email_address: "david@example.com",
      password: "password123",
      password_confirmation: "password123",
      approved: true
    )

    added_contacts = []
    @stub_brevo.define_singleton_method(:add_contact) do |email, name:|
      added_contacts << email
    end

    SyncBrevoContactsJob.perform_now(brevo_service: @stub_brevo)

    # Should not duplicate David
    assert_equal 1, User.where("LOWER(email_address) = ?", "david@example.com").count
    refute added_contacts.include?("david@example.com")
  end

  private

  def build_stub_brevo
    test_case = self
    stub = Object.new
    stub.define_singleton_method(:configured?) { true }
    stub.define_singleton_method(:list_contacts) do |limit:, offset:|
      contacts = test_case.instance_variable_get(:@brevo_contacts)
      offset == 0 ? contacts : []
    end
    stub.define_singleton_method(:add_contact) { |email, name:| }
    stub
  end
end
