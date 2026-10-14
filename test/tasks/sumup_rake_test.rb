require "test_helper"
require_relative "../test_helpers/sumup_test_helper"
require "rake"

class SumupRakeTest < ActiveSupport::TestCase
  include SumupTestHelper


  teardown { ENV.delete("DAYS") }

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("sumup:sync")
    Rake::Task["sumup:probe"].reenable
    Rake::Task["sumup:sync"].reenable
  end

  test "sumup:probe prints the report for the number of days asked for" do
    request = stub_request(:get, HISTORY_URL).with(query: hash_including("order" => "descending"))
      .to_return(status: 200, body: { "items" => [], "links" => [] }.to_json)

    ENV["DAYS"] = "7"
    output = capture_io { Rake::Task["sumup:probe"].invoke }.first

    assert_requested request
    assert_includes output, "SumUp returned 0 transactions"
    assert_match(/from #{Date.current - 7} to #{Date.current}/, output)
  end

  test "sumup:sync stores the transactions for the number of days asked for and says how many" do
    request = stub_request(:get, HISTORY_URL).with(query: hash_including("order" => "descending"))
      .to_return(status: 200, body: {
        "items" => [ { "id" => "r1", "transaction_id" => "r1", "amount" => 5.0, "currency" => "EUR",
                       "timestamp" => 2.days.ago.utc.iso8601, "status" => "SUCCESSFUL", "type" => "PAYMENT",
                       "payment_type" => "POS" } ],
        "links" => []
      }.to_json)

    ENV["DAYS"] = "30"
    output = capture_io { Rake::Task["sumup:sync"].invoke }.first

    assert_requested request
    assert_includes output, "Synced 1 SumUp transaction from the last 30 days"
    assert SumupTransaction.exists?(sumup_id: "r1")
  end
end
