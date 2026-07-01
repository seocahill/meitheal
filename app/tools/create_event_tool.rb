class CreateEventTool < ApplicationTool
  tool_name "create_event"
  description <<~DESC.squish
    Create a draft (unpublished) event owned by the owner account. Optionally
    pass from_email_id to copy the first image attachment of that email into the
    event image. An editor still has to publish the event.
  DESC

  arguments do
    required(:title).filled(:string)
    required(:starts_at).filled(:string).description("Start time, e.g. 2026-05-01 19:30")
    optional(:ends_at).filled(:string).description("End time")
    optional(:description).filled(:string)
    optional(:venue_name).filled(:string)
    optional(:venue_address).filled(:string)
    optional(:from_email_id).filled(:integer).description("Cached email to source an image from")
  end

  def call(title:, starts_at:, ends_at: nil, description: nil, venue_name: nil, venue_address: nil, from_email_id: nil)
    owner = owner_user
    return "No owner account configured; cannot create events." if owner.nil?

    parsed_start = parse_time(starts_at)
    return "Invalid start time #{starts_at.inspect}." if parsed_start.nil?

    if ends_at.present? && (parsed_end = parse_time(ends_at)).nil?
      return "Invalid end time #{ends_at.inspect}."
    end

    event = owner.events.build(
      title: title, starts_at: parsed_start, ends_at: parsed_end,
      description: description, venue_name: venue_name, venue_address: venue_address
    )
    event.save!

    image_note = attach_image_from_email(event, from_email_id)
    "Created draft event ##{event.id}: #{event.title}.#{image_note}"
  rescue ActiveRecord::RecordInvalid => e
    "Could not create event: #{e.record.errors.full_messages.join(', ')}"
  end

  private

  def attach_image_from_email(event, from_email_id)
    return "" if from_email_id.blank?

    email = CachedEmail.find_by(id: from_email_id)
    return " (email #{from_email_id} not found)" if email.nil?

    image = email.attachments.find { |att| att.content_type.to_s.start_with?("image/") }
    return " (no image attachment on email #{from_email_id})" if image.nil?

    event.image.attach(io: StringIO.new(image.download), filename: image.filename.to_s, content_type: image.content_type)
    " Attached image #{image.filename}."
  end

  def parse_time(value)
    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end
end
