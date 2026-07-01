class ListRecentPaymentsTool < ApplicationTool
  tool_name "list_recent_payments"
  description "List payments received in the last 30 days, optionally filtered by purpose."

  arguments do
    optional(:purpose).filled(:string).description("Filter by purpose: membership, booking, donation or other_purpose")
  end

  def call(purpose: nil)
    payments = Payment.recent.order(paid_on: :desc)
    payments = payments.where(purpose: purpose) if purpose.present?

    return "No recent payments found." if payments.empty?

    payments.map { |payment| format_line(payment) }.join("\n")
  end

  private

  def format_line(payment)
    "##{payment.id} €#{format('%.2f', payment.amount_euro)} [#{payment.purpose}] " \
      "#{payment.user_name} <#{payment.user_email}> — #{payment.description} (#{payment.paid_on})"
  end
end
