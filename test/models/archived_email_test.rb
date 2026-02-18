require "test_helper"

class ArchivedEmailTest < ActiveSupport::TestCase
  test "valid archived email with required attributes" do
    group = email_groups(:all_members)
    email = ArchivedEmail.new(
      email_group: group,
      from_address: "sender@example.com",
      subject: "Test Subject",
      body: "Test body",
      received_at: Time.current
    )
    assert email.valid?
  end

  test "requires email_group" do
    email = ArchivedEmail.new(from_address: "test@example.com", subject: "Test", body: "Body", received_at: Time.current)
    assert_not email.valid?
    assert_includes email.errors[:email_group], "must exist"
  end

  test "requires from_address" do
    group = email_groups(:all_members)
    email = ArchivedEmail.new(email_group: group, subject: "Test", body: "Body", received_at: Time.current)
    assert_not email.valid?
    assert_includes email.errors[:from_address], "can't be blank"
  end

  test "requires subject" do
    group = email_groups(:all_members)
    email = ArchivedEmail.new(email_group: group, from_address: "test@example.com", body: "Body", received_at: Time.current)
    assert_not email.valid?
    assert_includes email.errors[:subject], "can't be blank"
  end

  test "recent scope returns emails from last 30 days" do
    group = email_groups(:all_members)
    recent = ArchivedEmail.create!(
      email_group: group,
      from_address: "test@example.com",
      subject: "Recent",
      body: "Body",
      received_at: 1.week.ago
    )
    old = ArchivedEmail.create!(
      email_group: group,
      from_address: "test@example.com",
      subject: "Old",
      body: "Body",
      received_at: 2.months.ago
    )

    assert_includes ArchivedEmail.recent, recent
    assert_not_includes ArchivedEmail.recent, old
  end
end
