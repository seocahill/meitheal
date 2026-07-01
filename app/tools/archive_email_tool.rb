class ArchiveEmailTool < ApplicationTool
  tool_name "archive_email"
  description "Archive a cached inbox email by its id."

  arguments do
    required(:id).filled(:integer).description("The id of the email to archive")
  end

  def call(id:)
    email = CachedEmail.find_by(id: id)
    return "No email found with id #{id}." if email.nil?

    email.archived!
    "Archived email ##{id}: #{email.subject}"
  end
end
