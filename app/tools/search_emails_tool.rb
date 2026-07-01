class SearchEmailsTool < ApplicationTool
  tool_name "search_emails"
  description "Search cached inbox emails by subject, sender or summary. Returns matches with their ids."

  arguments do
    optional(:query).filled(:string).description("Text to match against subject, sender or summary")
    optional(:include_archived).filled(:bool).description("Include archived emails as well (default false)")
  end

  def call(query: nil, include_archived: false)
    scope = include_archived ? CachedEmail.all : CachedEmail.visible
    emails = scope.search(query).order(received_at: :desc).limit(25)

    return "No emails found." if emails.empty?

    emails.map { |email| format_line(email) }.join("\n")
  end

  private

  def format_line(email)
    received = email.received_at&.strftime("%Y-%m-%d")
    "##{email.id} [#{email.status}] #{email.from_address} — #{email.subject} (#{received})"
  end
end
