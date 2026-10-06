require "test_helper"

class SumupProbeTest < ActiveSupport::TestCase
  HISTORY_URL = "https://api.sumup.com/v2.1/merchants/TEST_MERCHANT/transactions/history".freeze
  NOW = Time.utc(2026, 10, 6, 12)

  def transaction(code:, id: SecureRandom.uuid, amount: 20.0, type: "ECOM", status: "SUCCESSFUL", at: "2026-10-01T10:00:00.000Z", summary: nil)
    { "id" => id, "transaction_id" => id, "transaction_code" => code, "amount" => amount, "currency" => "EUR",
      "timestamp" => at, "status" => status, "payment_type" => type, "type" => "PAYMENT", "product_summary" => summary }
  end

  def stub_history(items)
    stub_request(:get, HISTORY_URL).with(query: hash_including({}))
      .to_return(status: 200, body: { "items" => items, "links" => [] }.to_json)
  end

  def report(days: 60)
    SumupProbe.new(days: days, now: NOW).report
  end

  setup do
    @membership = memberships(:active_membership)
    Payment.where.not(sumup_transaction_id: nil).update_all(sumup_transaction_id: nil)
  end

  def local_payment(transaction_id, paid_on: Date.new(2026, 10, 1), status: :completed)
    Payment.create!(
      membership: @membership, amount_cents: 2000, paid_on: paid_on, payment_method: :sumup, status: status,
      sumup_transaction_id: transaction_id, user_email: "a@example.com", user_name: "A", description: "Fee"
    )
  end

  test "asks for the window newest first, in pages, from the number of days back" do
    request = stub_request(:get, HISTORY_URL)
      .with(query: { "order" => "descending", "limit" => "50", "oldest_time" => "2026-08-07T12:00:00Z" })
      .to_return(status: 200, body: { "items" => [], "links" => [] }.to_json)

    report(days: 60)

    assert_requested request
  end

  test "counts what SumUp returned by month and payment type" do
    stub_history([
      transaction(code: "A1", type: "POS", at: "2026-10-02T10:00:00Z"),
      transaction(code: "A2", type: "POS", at: "2026-10-03T10:00:00Z"),
      transaction(code: "A3", type: "ECOM", at: "2026-09-20T10:00:00Z"),
      transaction(code: "A4", type: "CASH", at: "2026-09-21T10:00:00Z")
    ])

    text = report

    assert_includes text, "SumUp returned 4 transactions"
    assert_match(/2026-10\s+POS 2/, text)
    assert_match(/2026-09\s+CASH 1\s+ECOM 1/, text)
  end

  test "counts by status so refunds and failures are visible" do
    stub_history([ transaction(code: "A1"), transaction(code: "A2", status: "FAILED"), transaction(code: "A3", status: "REFUNDED") ])

    assert_match(/FAILED 1\s+REFUNDED 1\s+SUCCESSFUL 1/, report)
  end

  test "says which payments we hold that SumUp did not return" do
    local_payment("known-id")
    local_payment("missing-id")
    stub_history([ transaction(code: "A1", id: "known-id") ])

    text = report

    assert_includes text, "We hold 2 SumUp payments in this window; SumUp returned 1 of them"
    assert_includes text, "missing-id"
    assert_not_includes text, "known-id\n"
  end

  test "reports when every payment we hold is in SumUp's results" do
    local_payment("known-id")
    stub_history([ transaction(code: "A1", id: "known-id") ])

    assert_includes report, "SumUp returned all of them"
  end

  test "ignores local payments outside the window and ones that never completed" do
    local_payment("too-old", paid_on: Date.new(2026, 1, 1))
    local_payment("still-pending", status: :pending)
    stub_history([])

    assert_includes report, "We hold 0 SumUp payments in this window"
  end

  test "lists successful SumUp payments we have no record of" do
    local_payment("known-id")
    stub_history([
      transaction(code: "A1", id: "known-id"),
      transaction(code: "READER1", type: "POS", amount: 15.5, summary: "Door sale"),
      transaction(code: "LOST1", type: "ECOM", amount: 20.0, status: "SUCCESSFUL"),
      transaction(code: "NOPE1", type: "ECOM", status: "FAILED")
    ])

    text = report

    assert_includes text, "2 successful SumUp payments have no payment record here"
    assert_includes text, "READER1"
    assert_includes text, "Door sale"
    assert_includes text, "LOST1"
    assert_not_includes text, "NOPE1"
  end

  test "shows the fields the first transaction carries and which id matched ours" do
    local_payment("known-id")
    stub_history([ transaction(code: "A1", id: "known-id") ])

    text = report

    assert_includes text, "Fields on a SumUp transaction:"
    assert_includes text, "transaction_code"
    assert_includes text, "Matched our records on: id 1, transaction_id 1"
  end

  test "an API failure is reported, not swallowed" do
    stub_request(:get, HISTORY_URL).with(query: hash_including({}))
      .to_return(status: 401, body: { "detail" => "Invalid API key" }.to_json)

    assert_raises(SumupCheckoutService::CheckoutError) { report }
  end
end
