require "test_helper"

class Admin::CalendarImportsControllerTest < ActionDispatch::IntegrationTest
  MINIMAL_ICAL = <<~ICAL
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//Test//Test//EN
    BEGIN:VEVENT
    SUMMARY:Test Event
    DTSTART:20270301T100000Z
    DTEND:20270301T120000Z
    DESCRIPTION:A test event
    END:VEVENT
    END:VCALENDAR
  ICAL

  setup do
    @owner = users(:owner)
    @editor = users(:editor)
    @viewer = users(:viewer)
    @space = spaces(:front_room)
  end

  # Access control
  test "owner can access new import form" do
    sign_in_as(@owner)
    get new_admin_calendar_import_path
    assert_response :success
  end

  test "editor cannot access import form" do
    sign_in_as(@editor)
    get new_admin_calendar_import_path
    assert_redirected_to root_path
  end

  test "viewer cannot access import form" do
    sign_in_as(@viewer)
    get new_admin_calendar_import_path
    assert_redirected_to root_path
  end

  test "unauthenticated user cannot access import form" do
    get new_admin_calendar_import_path
    assert_redirected_to new_session_path
  end

  # New form
  test "new form lists active spaces" do
    sign_in_as(@owner)
    get new_admin_calendar_import_path
    assert_response :success
    assert_includes response.body, @space.name
  end

  # Create - access control
  test "editor cannot post to create" do
    sign_in_as(@editor)
    post admin_calendar_imports_path, params: {
      space_id: @space.id,
      ical_file: ical_upload(MINIMAL_ICAL)
    }
    assert_redirected_to root_path
  end

  # Create - valid import
  test "owner can import valid ical file" do
    sign_in_as(@owner)
    assert_difference "Booking.count", 1 do
      post admin_calendar_imports_path, params: {
        space_id: @space.id,
        ical_file: ical_upload(MINIMAL_ICAL)
      }
    end
    assert_redirected_to calendar_path
  end

  test "imported booking is confirmed and assigned to importer" do
    sign_in_as(@owner)
    post admin_calendar_imports_path, params: {
      space_id: @space.id,
      ical_file: ical_upload(MINIMAL_ICAL)
    }
    booking = Booking.order(created_at: :desc).first
    assert booking.confirmed?
    assert_equal @owner.id, booking.user_id
    assert_equal @space.id, booking.space_id
    assert_equal "Test Event", booking.title
  end

  test "importing multiple events creates multiple bookings" do
    two_events = <<~ICAL
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VEVENT
      SUMMARY:Event One
      DTSTART:20270401T100000Z
      DTEND:20270401T110000Z
      END:VEVENT
      BEGIN:VEVENT
      SUMMARY:Event Two
      DTSTART:20270402T100000Z
      DTEND:20270402T110000Z
      END:VEVENT
      END:VCALENDAR
    ICAL

    sign_in_as(@owner)
    assert_difference "Booking.count", 2 do
      post admin_calendar_imports_path, params: {
        space_id: @space.id,
        ical_file: ical_upload(two_events)
      }
    end
  end

  test "import is idempotent for same event data" do
    sign_in_as(@owner)

    assert_difference "Booking.count", 1 do
      post admin_calendar_imports_path, params: {
        space_id: @space.id,
        ical_file: ical_upload(MINIMAL_ICAL)
      }
    end

    assert_no_difference "Booking.count" do
      post admin_calendar_imports_path, params: {
        space_id: @space.id,
        ical_file: ical_upload(MINIMAL_ICAL)
      }
    end

    assert_redirected_to calendar_path
  end

  # Create - missing file
  test "create without file re-renders form" do
    sign_in_as(@owner)
    assert_no_difference "Booking.count" do
      post admin_calendar_imports_path, params: { space_id: @space.id }
    end
    assert_response :unprocessable_entity
  end

  # Create - invalid space
  test "create with invalid space redirects" do
    sign_in_as(@owner)
    post admin_calendar_imports_path, params: {
      space_id: 0,
      ical_file: ical_upload(MINIMAL_ICAL)
    }
    assert_redirected_to new_admin_calendar_import_path
  end

  private

  def ical_upload(content)
    Rack::Test::UploadedFile.new(
      StringIO.new(content),
      "text/calendar",
      original_filename: "calendar.ics"
    )
  end
end
