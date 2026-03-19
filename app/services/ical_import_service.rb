class IcalImportService
  Result = Struct.new(:created, :skipped, :errors, keyword_init: true)

  def initialize(ical_data, space:, user:)
    @ical_data = ical_data
    @space = space
    @user = user
  end

  def import
    calendars = Icalendar::Calendar.parse(@ical_data)
    events = calendars.flat_map(&:events)

    created = 0
    skipped = []
    errors = []

    events.each do |event|
      result = import_event(event)
      case result
      when :created then created += 1
      when :skipped then skipped << event.summary
      else errors << "#{event.summary}: #{result}"
      end
    end

    Result.new(created: created, skipped: skipped, errors: errors)
  end

  private

  def import_event(event)
    starts_at = parse_time(event.dtstart)
    ends_at = parse_time(event.dtend) || starts_at + 1.hour if starts_at

    return :skipped if starts_at.nil?

    title = event.summary.to_s.presence || "Imported event"

    if Booking.exists?(space: @space, starts_at: starts_at, title: title)
      return :skipped
    end

    booking = Booking.new(
      title: title,
      description: event.description.to_s.presence,
      starts_at: starts_at,
      ends_at: ends_at,
      space: @space,
      user: @user,
      status: :confirmed,
      paid: true,
      agree_booking_rules: "1",
      agree_ethics: "1"
    )

    if booking.save
      :created
    else
      booking.errors.full_messages.join(", ")
    end
  end

  def parse_time(value)
    return nil if value.nil?
    value.respond_to?(:to_time) ? value.to_time : Time.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
