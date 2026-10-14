require "test_helper"
require_relative "../test_helpers/sumup_test_helper"

class SumupTransactionSyncTest < ActiveSupport::TestCase
  include SumupTestHelper

  NOW = Time.utc(2026, 10, 14, 12)

  def api_transaction(id:, amount: 20.0, status: "SUCCESSFUL", at: "2026-10-10T10:00:00.000Z", **attrs)
    { "id" => id, "transaction_id" => "txn-#{id}", "transaction_code" => "CODE-#{id}", "amount" => amount,
      "currency" => "EUR", "timestamp" => at, "status" => status, "payment_type" => "POS", "type" => "PAYMENT",
      "product_summary" => "Door sale" }.merge(attrs)
  end

  def stub_history(items)
    stub_request(:get, HISTORY_URL).with(query: hash_including({}))
      .to_return(status: 200, body: { "items" => items, "links" => [] }.to_json)
  end

  def sync(days: 14)
    SumupTransactionSync.new(days: days, now: NOW).call
  end

  test "asks for the window newest first, in pages, from the number of days back" do
    request = stub_request(:get, HISTORY_URL)
      .with(query: { "order" => "descending", "limit" => "50", "oldest_time" => "2026-09-30T12:00:00Z" })
      .to_return(status: 200, body: { "items" => [], "links" => [] }.to_json)

    sync(days: 14)

    assert_requested request
  end

  test "stores each transaction SumUp returns" do
    stub_history([ api_transaction(id: "a1", amount: 15.5), api_transaction(id: "a2", amount: 0.1, status: "FAILED") ])

    assert_difference -> { SumupTransaction.count }, 2 do
      sync
    end

    stored = SumupTransaction.find_by!(sumup_id: "a1")
    assert_equal "txn-a1", stored.transaction_id
    assert_equal "CODE-a1", stored.transaction_code
    assert_equal 1550, stored.amount_cents
    assert_equal "EUR", stored.currency
    assert_equal "POS", stored.payment_type
    assert_equal "PAYMENT", stored.kind
    assert_equal "SUCCESSFUL", stored.status
    assert_equal "Door sale", stored.product_summary
    assert_equal Time.utc(2026, 10, 10, 10), stored.occurred_at
    assert_equal 10, SumupTransaction.find_by!(sumup_id: "a2").amount_cents
  end

  test "running again does not duplicate and picks up a status change" do
    stub_history([ api_transaction(id: "a1") ])
    sync

    stub_history([ api_transaction(id: "a1", status: "REFUNDED") ])

    assert_no_difference -> { SumupTransaction.count } do
      sync
    end
    assert_equal "REFUNDED", SumupTransaction.find_by!(sumup_id: "a1").status
  end

  test "returns how many transactions SumUp returned" do
    stub_history([ api_transaction(id: "a1"), api_transaction(id: "a2") ])

    assert_equal 2, sync
  end

  test "nothing returned stores nothing" do
    stub_history([])

    assert_no_difference -> { SumupTransaction.count } do
      assert_equal 0, sync
    end
  end

  test "an API failure is raised and nothing is stored" do
    stub_request(:get, HISTORY_URL).with(query: hash_including({}))
      .to_return(status: 401, body: { "detail" => "Invalid API key" }.to_json)

    assert_no_difference -> { SumupTransaction.count } do
      assert_raises(SumupCheckoutService::CheckoutError) { sync }
    end
  end
end
