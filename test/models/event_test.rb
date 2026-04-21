require "test_helper"

class EventTest < ActiveSupport::TestCase
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
  end

  test "valid event with required attributes" do
    event = Event.new(
      title: "Test Event",
      starts_at: 1.week.from_now,
      user: @viewer
    )
    assert event.valid?
  end

  test "requires title" do
    event = Event.new(starts_at: 1.week.from_now, user: @viewer)
    assert_not event.valid?
    assert_includes event.errors[:title], "can't be blank"
  end

  test "requires starts_at" do
    event = Event.new(title: "Test", user: @viewer)
    assert_not event.valid?
    assert_includes event.errors[:starts_at], "can't be blank"
  end

  test "requires user" do
    event = Event.new(title: "Test", starts_at: 1.week.from_now)
    assert_not event.valid?
    assert_includes event.errors[:user], "must exist"
  end

  test "defaults to draft (not published)" do
    event = Event.new(title: "Test", starts_at: 1.week.from_now, user: @viewer)
    assert_not event.published?
  end

  test "scope published returns only published events" do
    draft = Event.create!(title: "Draft", starts_at: 1.week.from_now, user: @viewer, published: false)
    published = Event.create!(title: "Published", starts_at: 1.week.from_now, user: @viewer, published: true)

    assert_includes Event.published, published
    assert_not_includes Event.published, draft
  end

  test "scope draft returns only unpublished events" do
    draft = Event.create!(title: "Draft", starts_at: 1.week.from_now, user: @viewer, published: false)
    published = Event.create!(title: "Published", starts_at: 1.week.from_now, user: @viewer, published: true)

    assert_includes Event.draft, draft
    assert_not_includes Event.draft, published
  end

  test "scope upcoming returns future events ordered by date" do
    past = Event.create!(title: "Past", starts_at: 1.week.ago, user: @viewer)
    future1 = Event.create!(title: "Future 1", starts_at: 3.weeks.from_now, user: @viewer)
    future2 = Event.create!(title: "Future 2", starts_at: 4.days.from_now, user: @viewer)

    upcoming = Event.upcoming
    assert_not_includes upcoming, past

    # Verify ordering: earlier dates come first
    future2_index = upcoming.to_a.index(future2)
    future1_index = upcoming.to_a.index(future1)
    assert future2_index < future1_index, "Earlier event should appear before later event"
  end

  test "editable_by? returns true for event owner" do
    event = Event.new(user: @viewer)
    assert event.editable_by?(@viewer)
  end

  test "editable_by? returns true for editors" do
    event = Event.new(user: @viewer)
    assert event.editable_by?(@editor)
  end

  test "editable_by? returns true for owners" do
    event = Event.new(user: @viewer)
    assert event.editable_by?(@owner)
  end

  test "editable_by? returns false for other viewers" do
    other_viewer = User.create!(email_address: "other@example.com", password: "password", role: :viewer)
    event = Event.new(user: @viewer)
    assert_not event.editable_by?(other_viewer)
  end

  test "publishable_by? returns true for editors" do
    event = Event.new(user: @viewer)
    assert event.publishable_by?(@editor)
  end

  test "publishable_by? returns true for owners" do
    event = Event.new(user: @viewer)
    assert event.publishable_by?(@owner)
  end

  test "publishable_by? returns false for viewers" do
    event = Event.new(user: @viewer)
    assert_not event.publishable_by?(@viewer)
  end

  test "ensure_qr_code attaches a PNG qr code" do
    event = Event.create!(title: "Test", starts_at: 1.week.from_now, user: @viewer)
    assert_not event.qr_code.attached?

    event.ensure_qr_code("https://thencf.art/events/#{event.id}")

    assert event.qr_code.attached?
    assert_equal "image/png", event.qr_code.content_type
  end

  test "ensure_qr_code does not overwrite an existing attachment" do
    event = Event.create!(title: "Test", starts_at: 1.week.from_now, user: @viewer)
    event.ensure_qr_code("https://thencf.art/events/#{event.id}")
    original_key = event.qr_code.key

    event.ensure_qr_code("https://thencf.art/events/#{event.id}")

    assert_equal original_key, event.qr_code.key
  end

  test "ensure_qr_code is a no-op for unpersisted events" do
    event = Event.new(title: "Test", starts_at: 1.week.from_now, user: @viewer)
    assert_nothing_raised { event.ensure_qr_code("https://thencf.art/events/new") }
    assert_not event.qr_code.attached?
  end
end
