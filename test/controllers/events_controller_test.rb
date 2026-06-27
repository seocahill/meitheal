require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @draft_event = events(:draft_event)
    @published_event = events(:published_event)
  end

  # Public access tests
  test "index shows only published events to public" do
    get events_path
    assert_response :success
    assert_includes response.body, @published_event.title
    assert_not_includes response.body, @draft_event.title
  end

  test "show displays published event to public" do
    get event_path(@published_event)
    assert_response :success
    assert_includes response.body, @published_event.title
  end

  test "show redirects for draft event when not signed in" do
    get event_path(@draft_event)
    assert_redirected_to events_path
  end

  # Authenticated user tests
  test "signed in user can view their own draft event" do
    sign_in_as(@viewer)
    get event_path(@draft_event)
    assert_response :success
  end

  test "editor can view any draft event" do
    sign_in_as(@editor)
    get event_path(@draft_event)
    assert_response :success
  end

  # Create tests
  test "new requires authentication" do
    get new_event_path
    assert_redirected_to new_session_path
  end

  test "signed in user can access new event form" do
    sign_in_as(@viewer)
    get new_event_path
    assert_response :success
  end

  test "new event form defaults starts_at to noon today" do
    sign_in_as(@viewer)
    travel_to Time.zone.parse("2026-05-19 09:30") do
      get new_event_path
      assert_response :success
      assert_includes response.body, "2026-05-19T12:00"
    end
  end

  test "signed in user can create event as draft" do
    sign_in_as(@viewer)
    assert_difference "Event.count" do
      post events_path, params: {
        event: {
          title: "New Event",
          starts_at: 1.week.from_now,
          description: "Event description"
        }
      }
    end
    event = Event.last
    assert_not event.published?
    assert_equal @viewer, event.user
    assert_redirected_to event_path(event)
  end

  # Edit tests
  test "event owner can edit their event" do
    sign_in_as(@viewer)
    get edit_event_path(@draft_event)
    assert_response :success
  end

  test "editor can edit any event" do
    sign_in_as(@editor)
    get edit_event_path(@draft_event)
    assert_response :success
  end

  test "other viewer cannot edit event they dont own" do
    other_viewer = User.create!(email_address: "other@test.com", password: "password", role: :viewer)
    sign_in_as(other_viewer)
    get edit_event_path(@draft_event)
    assert_redirected_to root_path
  end

  # Update tests
  test "event owner can update their event" do
    sign_in_as(@viewer)
    patch event_path(@draft_event), params: {
      event: { title: "Updated Title" }
    }
    assert_redirected_to event_path(@draft_event)
    @draft_event.reload
    assert_equal "Updated Title", @draft_event.title
  end

  test "viewer cannot publish their own event" do
    sign_in_as(@viewer)
    patch event_path(@draft_event), params: {
      event: { published: true }
    }
    @draft_event.reload
    assert_not @draft_event.published?
  end

  # Publish tests
  test "editor can publish event" do
    sign_in_as(@editor)
    patch publish_event_path(@draft_event)
    assert_redirected_to event_path(@draft_event)
    @draft_event.reload
    assert @draft_event.published?
  end

  test "viewer cannot publish event" do
    sign_in_as(@viewer)
    patch publish_event_path(@draft_event)
    assert_redirected_to root_path
    @draft_event.reload
    assert_not @draft_event.published?
  end

  test "editor can unpublish event" do
    sign_in_as(@editor)
    patch unpublish_event_path(@published_event)
    assert_redirected_to event_path(@published_event)
    @published_event.reload
    assert_not @published_event.published?
  end

  # User reassignment tests
  test "editor can reassign event to another user" do
    sign_in_as(@editor)
    other_viewer = users(:owner)
    patch event_path(@draft_event), params: {
      event: { user_id: other_viewer.id }
    }
    assert_redirected_to event_path(@draft_event)
    @draft_event.reload
    assert_equal other_viewer, @draft_event.user
  end

  test "viewer cannot reassign event user" do
    sign_in_as(@viewer)
    original_user = @draft_event.user
    patch event_path(@draft_event), params: {
      event: { user_id: users(:editor).id }
    }
    @draft_event.reload
    assert_equal original_user, @draft_event.user
  end

  # Delete tests
  test "owner can delete any event" do
    sign_in_as(@owner)
    assert_difference "Event.count", -1 do
      delete event_path(@draft_event)
    end
    assert_redirected_to events_path
  end

  test "viewer can delete their own event" do
    sign_in_as(@viewer)
    assert_difference "Event.count", -1 do
      delete event_path(@draft_event)
    end
  end

  test "viewer cannot delete event they dont own" do
    other_viewer = User.create!(email_address: "other2@test.com", password: "password", role: :viewer)
    sign_in_as(other_viewer)
    assert_no_difference "Event.count" do
      delete event_path(@draft_event)
    end
    assert_redirected_to root_path
  end
end
