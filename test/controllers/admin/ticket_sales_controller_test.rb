require "test_helper"

class Admin::TicketSalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = users(:editor)
    @viewer = users(:viewer)
    @event = events(:ticketed_event)
  end

  # index

  test "editor can access ticket sales index" do
    sign_in_as(@editor)
    get admin_ticket_sales_path
    assert_response :success
  end

  test "viewer cannot access ticket sales index" do
    sign_in_as(@viewer)
    get admin_ticket_sales_path
    assert_redirected_to root_path
  end

  test "index lists events that have tickets" do
    sign_in_as(@editor)
    get admin_ticket_sales_path
    assert_response :success
    assert_match @event.title, response.body
  end

  # show

  test "editor can view ticket sales for an event" do
    sign_in_as(@editor)
    get admin_ticket_sale_path(@event)
    assert_response :success
    assert_match @event.title, response.body
    assert_match tickets(:paid_ticket).buyer_name, response.body
  end

  test "viewer cannot view ticket sales for an event" do
    sign_in_as(@viewer)
    get admin_ticket_sale_path(@event)
    assert_redirected_to root_path
  end

  # add_booking

  test "editor can add a reserved booking" do
    sign_in_as(@editor)
    assert_difference -> { @event.tickets.reserved.count }, 1 do
      post add_booking_admin_ticket_sale_path(@event),
        params: { buyer_name: "Door Guest", buyer_email: "guest@example.com", quantity: 3 }
    end
    assert_redirected_to admin_ticket_sale_path(@event)
    ticket = @event.tickets.reserved.order(:created_at).last
    assert_equal "Door Guest", ticket.buyer_name
    assert_equal 3, ticket.quantity
    assert_equal @event.ticket_price_cents * 3, ticket.amount_cents
  end

  test "reserved booking reduces remaining tickets" do
    sign_in_as(@editor)
    before = @event.tickets_remaining
    post add_booking_admin_ticket_sale_path(@event),
      params: { buyer_name: "Door Guest", quantity: 4 }
    assert_equal before - 4, @event.reload.tickets_remaining
  end

  test "editor can add a booking without an email" do
    sign_in_as(@editor)
    assert_difference -> { @event.tickets.reserved.count }, 1 do
      post add_booking_admin_ticket_sale_path(@event),
        params: { buyer_name: "Cash At Door", quantity: 1 }
    end
  end

  test "booking cannot exceed remaining capacity" do
    sign_in_as(@editor)
    assert_no_difference -> { @event.tickets.reserved.count } do
      post add_booking_admin_ticket_sale_path(@event),
        params: { buyer_name: "Too Many", quantity: 999 }
    end
    assert_redirected_to admin_ticket_sale_path(@event)
    assert_match(/remaining/, flash[:alert])
  end

  test "viewer cannot add a booking" do
    sign_in_as(@viewer)
    assert_no_difference -> { @event.tickets.reserved.count } do
      post add_booking_admin_ticket_sale_path(@event),
        params: { buyer_name: "Door Guest", quantity: 1 }
    end
    assert_redirected_to root_path
  end
end
