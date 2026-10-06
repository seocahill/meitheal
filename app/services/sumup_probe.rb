# Read-only check of what SumUp's API returns against the SumUp payments we hold.
# Writes nothing. Run on production with:
#   puts SumupProbe.new(days: 60).report
class SumupProbe
  include ActionView::Helpers::TextHelper

  PAGE_SIZE = 50
  UNMATCHED_SHOWN = 30

  def initialize(days: 60, now: Time.current, service: SumupCheckoutService.new)
    @days = days
    @now = now
    @service = service
  end

  def report
    since = @now - @days.days
    @transactions = @service.list_transactions(order: "descending", limit: PAGE_SIZE, oldest_time: since)
    @window = since.to_date..@now.to_date

    [ summary, by_month, by_status, fields, held_payments, held_tickets, unmatched_payments ].join("\n\n")
  end

  private

  def summary
    "SumUp returned #{pluralize(@transactions.size, 'transaction')} from #{@window.begin} to #{@window.end}."
  end

  def by_month
    rows = @transactions.group_by { |t| t["timestamp"].to_s[0, 7] }.sort.reverse.map do |month, items|
      "  #{month}  #{tally(items, 'payment_type')}"
    end
    "By month and payment type:\n#{rows.join("\n")}"
  end

  def by_status
    "By status:\n  #{tally(@transactions, 'status')}"
  end

  def tally(items, key)
    items.group_by { |t| t[key] }.sort_by { |name, _| name.to_s }.map { |name, group| "#{name} #{group.size}" }.join("  ")
  end

  def fields
    first = @transactions.first
    "Fields on a SumUp transaction: #{first ? first.keys.join(', ') : 'none, nothing was returned'}"
  end

  def held_payments
    held_section("SumUp payment", Payment.sumup.completed.where(paid_on: @window))
  end

  # Event tickets are paid through SumUp too, but are stored on tickets, not payments.
  # A ticket's updated_at is when it was paid.
  def held_tickets
    held_section("paid SumUp ticket", Ticket.paid.where(updated_at: @window.begin.beginning_of_day..@window.end.end_of_day))
  end

  # What we hold in the window, and whether SumUp returned each one.
  def held_section(label, scope)
    held_ids = scope.where.not(sumup_transaction_id: nil).pluck(:sumup_transaction_id)
    returned = held_ids & sumup_ids
    missing = held_ids - returned

    lines = [ "We hold #{pluralize(held_ids.size, label)} in this window; SumUp returned #{missing.empty? ? 'all of them' : "#{returned.size} of them"}." ]
    lines << "Matched our records on: #{matched_on(returned)}" if returned.any?
    lines << "Not returned by SumUp:\n#{missing.map { |id| "  #{id}" }.join("\n")}" if missing.any?
    lines.join("\n")
  end

  def matched_on(returned)
    %w[id transaction_id].map { |key| "#{key} #{@transactions.count { |t| returned.include?(t[key]) }}" }.join(", ")
  end

  # Successful payments in SumUp with no payment or ticket record here: reader sales and lost checkouts.
  def unmatched_payments
    known = Payment.where.not(sumup_transaction_id: nil).pluck(:sumup_transaction_id) +
            Ticket.where.not(sumup_transaction_id: nil).pluck(:sumup_transaction_id)
    unmatched = @transactions.select do |t|
      t["status"] == "SUCCESSFUL" && t["type"] == "PAYMENT" && (known & [ t["id"], t["transaction_id"] ]).empty?
    end

    lines = [ "#{pluralize(unmatched.size, 'successful SumUp payment')} #{unmatched.size == 1 ? 'has' : 'have'} no payment record here#{':' if unmatched.any?}" ]
    unmatched.first(UNMATCHED_SHOWN).each { |t| lines << unmatched_line(t) }
    lines << "  ...and #{unmatched.size - UNMATCHED_SHOWN} more" if unmatched.size > UNMATCHED_SHOWN
    lines.join("\n")
  end

  def unmatched_line(transaction)
    time = Time.zone.parse(transaction["timestamp"].to_s)&.strftime("%Y-%m-%d %H:%M")
    "  #{time}  #{transaction['transaction_code']}  #{transaction['payment_type']}  EUR #{format('%.2f', transaction['amount'].to_f)}  #{transaction['product_summary']}".rstrip
  end

  def sumup_ids
    @transactions.flat_map { |t| [ t["id"], t["transaction_id"] ] }.compact.uniq
  end
end
