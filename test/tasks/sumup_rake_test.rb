require "test_helper"
require_relative "../test_helpers/sumup_test_helper"
require "rake"

class SumupRakeTest < ActiveSupport::TestCase
  include SumupTestHelper


  teardown { ENV.delete("DAYS") }

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("sumup:probe")
    Rake::Task["sumup:probe"].reenable
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
end
