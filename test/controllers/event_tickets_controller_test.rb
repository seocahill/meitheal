require "test_helper"

class EventTicketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:ticketed_event)
    @event_no_ticketing = events(:published_event)
  end

  # new

  test "new shows ticket purchase form for ticketed event" do
    get new_event_tickets_path(@event)
    assert_response :success
    assert_match "Buy Tickets", response.body
  end

  test "new redirects when ticketing is not enabled" do
    get new_event_tickets_path(@event_no_ticketing)
    assert_redirected_to event_path(@event_no_ticketing)
  end

  test "new redirects when event is sold out" do
    @event.update!(capacity: 1)
    get new_event_tickets_path(@event)
    assert_redirected_to event_path(@event)
  end

  # create_checkout

  test "create_checkout creates a pending ticket and returns checkout_id" do
    stub_request(:post, SumupCheckoutService::CHECKOUT_URL)
      .to_return(
        status: 200,
        body: { "id" => "checkout-ticket-new" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "Ticket.count", 1 do
      post create_checkout_event_tickets_path(@event),
        params: { buyer_name: "Test Person", buyer_email: "test@example.com", quantity: 2 },
        as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "checkout-ticket-new", json["checkout_id"]

    ticket = Ticket.last
    assert ticket.pending?
    assert_equal "Test Person", ticket.buyer_name
    assert_equal "test@example.com", ticket.buyer_email
    assert_equal 2, ticket.quantity
    assert_equal 2000, ticket.amount_cents
    assert_equal "checkout-ticket-new", ticket.sumup_checkout_id
  end

  test "create_checkout rejects invalid quantity" do
    post create_checkout_event_tickets_path(@event),
      params: { buyer_name: "Test", buyer_email: "test@example.com", quantity: 0 },
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  test "create_checkout rejects missing buyer_name" do
    post create_checkout_event_tickets_path(@event),
      params: { buyer_email: "test@example.com", quantity: 1 },
      as: :json

    assert_response :unprocessable_entity
  end

  test "create_checkout rejects when event has no ticketing" do
    post create_checkout_event_tickets_path(@event_no_ticketing),
      params: { buyer_name: "Test", buyer_email: "test@example.com", quantity: 1 },
      as: :json

    assert_response :unprocessable_entity
  end

  test "create_checkout rejects quantity exceeding remaining capacity" do
    @event.update!(capacity: 2)

    post create_checkout_event_tickets_path(@event),
      params: { buyer_name: "Test", buyer_email: "test@example.com", quantity: 5 },
      as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_match /ticket/, json["error"].downcase
  end

  # complete

  test "complete with PAID status marks ticket as paid and sends email" do
    ticket = tickets(:pending_ticket)

    stub_request(:get, "#{SumupCheckoutService::CHECKOUT_URL}/#{ticket.sumup_checkout_id}")
      .to_return(
        status: 200,
        body: { "status" => "PAID", "transaction_id" => "txn-new" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_emails 1 do
      get complete_event_tickets_path(@event, checkout_id: ticket.sumup_checkout_id)
    end

    assert_redirected_to event_path(@event)
    assert_match /confirmation.*sent/i, flash[:notice]
    assert ticket.reload.paid?
    assert_equal "txn-new", ticket.reload.sumup_transaction_id
  end

  test "complete with failed payment marks ticket as failed" do
    ticket = tickets(:pending_ticket)

    stub_request(:get, "#{SumupCheckoutService::CHECKOUT_URL}/#{ticket.sumup_checkout_id}")
      .to_return(
        status: 200,
        body: { "status" => "FAILED" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get complete_event_tickets_path(@event, checkout_id: ticket.sumup_checkout_id)

    assert_redirected_to event_path(@event)
    assert flash[:alert].present?
    assert ticket.reload.failed?
  end

  test "complete with no checkout_id redirects to event" do
    get complete_event_tickets_path(@event)
    assert_redirected_to event_path(@event)
  end
end
