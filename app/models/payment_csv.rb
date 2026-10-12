require "csv"

# Payments as a CSV for accounts.
class PaymentCsv
  include SpreadsheetSafe

  HEADERS = [ "Date", "Name", "Email", "Purpose", "Description", "Amount (EUR)", "Method", "Status", "Notes", "SumUp transaction" ].freeze

  def initialize(payments)
    @payments = payments
  end

  def to_s
    CSV.generate do |csv|
      csv << HEADERS
      @payments.find_each { |payment| csv << row(payment) }
    end
  end

  private

  def row(payment)
    [
      payment.paid_on.iso8601,
      payment.user_name,
      payment.user_email,
      payment.purpose&.humanize&.sub("Other purpose", "Other"),
      payment.description,
      format("%.2f", payment.amount_euro),
      payment.payment_method.humanize,
      payment.status.humanize,
      payment.notes,
      payment.sumup_transaction_id
    ].map { |value| safe(value) }
  end
end
