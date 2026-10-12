require "csv"

# Memberships as a CSV for the membership list. Rows keep the order of the scope.
class MembershipCsv
  include SpreadsheetSafe

  HEADERS = [ "Name", "Email", "Type", "Payment status", "Started", "Paid until", "Last payment", "Last payment method", "Notes" ].freeze

  def initialize(memberships)
    @memberships = memberships
  end

  def to_s
    CSV.generate do |csv|
      csv << HEADERS
      @memberships.each { |membership| csv << row(membership) }
    end
  end

  private

  def row(membership)
    last_payment = membership.last_payment
    [
      membership.user.profile&.name,
      membership.user.email_address,
      membership.membership_type.humanize,
      membership.payment_status.to_s.humanize,
      membership.starts_on&.iso8601,
      membership.expires_on&.iso8601,
      last_payment&.paid_on&.iso8601,
      last_payment&.payment_method&.humanize,
      membership.notes
    ].map { |value| safe(value) }
  end
end
