require "csv"

# Payments as a CSV for accounts. Text is prefixed with an apostrophe when a
# spreadsheet would otherwise run it as a formula.
class PaymentCsv
  HEADERS = [ "Date", "Name", "Email", "Purpose", "Description", "Amount (EUR)", "Method", "Status", "Notes", "SumUp transaction" ].freeze
  FORMULA_START = /\A[=+\-@\t\r]/

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

  def safe(value)
    value.is_a?(String) && value.match?(FORMULA_START) ? "'#{value}" : value
  end
end
