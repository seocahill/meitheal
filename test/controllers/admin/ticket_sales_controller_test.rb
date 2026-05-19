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
end
