require "test_helper"
require_relative "../test_helpers/sumup_test_helper"

class SyncSumupTransactionsJobTest < ActiveJob::TestCase
  include SumupTestHelper

  test "stores the last two weeks of SumUp transactions" do
    request = stub_request(:get, HISTORY_URL)
      .with(query: hash_including("oldest_time" => 14.days.ago.utc.beginning_of_minute.iso8601))
      .to_return(status: 200, body: {
        "items" => [ { "id" => "j1", "transaction_id" => "j1", "amount" => 5.0, "currency" => "EUR",
                       "timestamp" => 1.day.ago.utc.iso8601, "status" => "SUCCESSFUL", "type" => "PAYMENT",
                       "payment_type" => "POS" } ],
        "links" => []
      }.to_json)

    assert_difference -> { SumupTransaction.count }, 1 do
      travel_to(Time.current.beginning_of_minute) { SyncSumupTransactionsJob.perform_now }
    end
    assert_requested request
  end
end
