require "test_helper"

class SumupCheckoutServiceTest < ActiveSupport::TestCase
  HISTORY_URL = "https://api.sumup.com/v2.1/merchants/TEST_MERCHANT/transactions/history".freeze

  def page(items, next_query: nil)
    { "items" => items, "links" => next_query ? [ { "rel" => "next", "href" => next_query } ] : [] }.to_json
  end

  def stub_page(query: nil, body:, status: 200)
    url = query ? "#{HISTORY_URL}?#{query}" : HISTORY_URL
    stub_request(:get, url).with(headers: { "Authorization" => "Bearer test-api-key" })
      .to_return(status: status, body: body, headers: { "Content-Type" => "application/json" })
  end

  test "list_transactions sends the filters to the merchant's history endpoint" do
    request = stub_request(:get, HISTORY_URL)
      .with(query: { "order" => "descending", "limit" => "100", "oldest_time" => "2026-09-01T00:00:00Z", "statuses[]" => "SUCCESSFUL" })
      .to_return(status: 200, body: page([ { "id" => "a" } ]))

    items = SumupCheckoutService.new.list_transactions(
      order: "descending", limit: 100, oldest_time: Time.utc(2026, 9, 1), statuses: [ "SUCCESSFUL" ]
    )

    assert_requested request
    assert_equal [ { "id" => "a" } ], items
  end

  test "list_transactions follows next links, which are query strings, until there are none" do
    stub_request(:get, HISTORY_URL).with(query: { "limit" => "2" })
      .to_return(status: 200, body: page([ { "id" => "1" }, { "id" => "2" } ], next_query: "limit=2&oldest_ref=ref-2&order=ascending"))
    stub_request(:get, HISTORY_URL).with(query: { "limit" => "2", "oldest_ref" => "ref-2", "order" => "ascending" })
      .to_return(status: 200, body: page([ { "id" => "3" }, { "id" => "4" } ], next_query: "limit=2&oldest_ref=ref-4&order=ascending"))
    stub_request(:get, HISTORY_URL).with(query: { "limit" => "2", "oldest_ref" => "ref-4", "order" => "ascending" })
      .to_return(status: 200, body: page([ { "id" => "5" } ]))

    items = SumupCheckoutService.new.list_transactions(limit: 2)

    assert_equal %w[1 2 3 4 5], items.map { |item| item["id"] }
  end

  test "list_transactions ignores links that are not the next page" do
    stub_request(:get, HISTORY_URL)
      .to_return(status: 200, body: { "items" => [ { "id" => "1" } ], "links" => [ { "rel" => "prev", "href" => "limit=2&newest_ref=x" } ] }.to_json)

    assert_equal 1, SumupCheckoutService.new.list_transactions.size
  end

  test "list_transactions raises at the page limit instead of looping forever or returning part of the history" do
    stub = stub_request(:get, HISTORY_URL).with(query: hash_including({}))
      .to_return(status: 200, body: page([ { "id" => "1" } ], next_query: "oldest_ref=same"))

    error = assert_raises(SumupCheckoutService::CheckoutError) { SumupCheckoutService.new.list_transactions(max_pages: 3) }

    assert_match(/more than 3 pages/, error.message)
    assert_requested stub, times: 3
  end

  test "list_transactions raises with SumUp's message when the request is refused" do
    stub_request(:get, HISTORY_URL).to_return(status: 401, body: { "title" => "Unauthorized", "detail" => "Invalid API key" }.to_json)

    error = assert_raises(SumupCheckoutService::CheckoutError) { SumupCheckoutService.new.list_transactions }

    assert_match(/401/, error.message)
    assert_match(/Invalid API key/, error.message)
  end

  test "list_transactions raises when a later page fails rather than returning part of the history" do
    stub_request(:get, HISTORY_URL).with(query: { "limit" => "1" })
      .to_return(status: 200, body: page([ { "id" => "1" } ], next_query: "limit=1&oldest_ref=r1"))
    stub_request(:get, HISTORY_URL).with(query: { "limit" => "1", "oldest_ref" => "r1" })
      .to_return(status: 500, body: "")

    assert_raises(SumupCheckoutService::CheckoutError) { SumupCheckoutService.new.list_transactions(limit: 1) }
  end

  test "list_transactions raises when the response is not JSON" do
    stub_request(:get, HISTORY_URL).to_return(status: 200, body: "<html>maintenance</html>")

    assert_raises(SumupCheckoutService::CheckoutError) { SumupCheckoutService.new.list_transactions }
  end
end
