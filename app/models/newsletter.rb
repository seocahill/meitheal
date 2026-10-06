# The site's own copy of a newsletter that was sent through Brevo, kept so the
# old pages and links keep working and the archive outlives the Brevo account.
# Newsletters are written and sent in Brevo; nothing in the app creates these.
class Newsletter < ApplicationRecord
  has_rich_text :content

  enum :status, { draft: 0, sent: 1 }, default: :draft

  scope :sent, -> { where(status: :sent) }
end
