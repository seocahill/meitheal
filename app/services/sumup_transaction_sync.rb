# Copies SumUp's transaction history for the last few days into SumupTransaction.
# Safe to run repeatedly: transactions are matched on SumUp's id, so a status
# change such as a refund updates the row already held.
class SumupTransactionSync
  PAGE_SIZE = 50

  def initialize(days:, now: Time.current, service: SumupCheckoutService.new)
    @days = days
    @now = now
    @service = service
  end

  # Returns how many transactions SumUp returned.
  def call
    transactions = @service.list_transactions(order: "descending", limit: PAGE_SIZE, oldest_time: @now - @days.days)
    rows = transactions.map { |transaction| row(transaction) }
    SumupTransaction.upsert_all(rows, unique_by: :sumup_id) if rows.any?
    rows.size
  end

  private

  def row(transaction)
    {
      sumup_id: transaction["id"],
      transaction_id: transaction["transaction_id"],
      transaction_code: transaction["transaction_code"],
      kind: transaction["type"],
      status: transaction["status"],
      payment_type: transaction["payment_type"],
      amount_cents: (BigDecimal(transaction["amount"].to_s) * 100).round,
      currency: transaction["currency"],
      product_summary: transaction["product_summary"],
      occurred_at: Time.zone.parse(transaction["timestamp"].to_s)
    }
  end
end
