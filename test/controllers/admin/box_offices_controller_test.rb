require "test_helper"

class Admin::BoxOfficesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = users(:editor)
    @viewer = users(:viewer)
    @event = events(:ticketed_event)
    @paid = tickets(:paid_ticket)
  end

  # show

  test "editor can open the box office" do
    sign_in_as(@editor)
    get admin_box_office_path(@event)
    assert_response :success
    assert_match @event.title, response.body
    assert_match @paid.buyer_name, response.body
    assert_select "p", text: %r{0\s*/\s*50}
  end

  test "viewer cannot open the box office" do
    sign_in_as(@viewer)
    get admin_box_office_path(@event)
    assert_redirected_to root_path
  end

  test "box office lists only paid and reserved tickets" do
    sign_in_as(@editor)
    get admin_box_office_path(@event)
    assert_no_match tickets(:pending_ticket).buyer_name, response.body
  end

  test "search filters the door list" do
    Ticket.create!(event: @event, buyer_name: "Aoife Walsh", quantity: 1, amount_cents: 1000, status: :reserved)
    sign_in_as(@editor)
    get admin_box_office_path(@event, q: "aoife")
    assert_match "Aoife Walsh", response.body
    assert_no_match @paid.buyer_name, response.body
  end

  test "shows when the box office closes" do
    sign_in_as(@editor)
    get admin_box_office_path(@event)
    assert_match "Box office open", response.body
    assert_match @event.box_office_closes_at.strftime("%H:%M"), response.body
  end

  test "shows the box office as closed when the room is full" do
    @event.update!(capacity: 1)
    @paid.update!(checked_in_count: 1)
    sign_in_as(@editor)
    get admin_box_office_path(@event)
    assert_match "Box office closed", response.body
    assert_match "room is full", response.body
  end

  # check_in

  test "editor can check in one person on a booking" do
    @paid.update!(quantity: 3)
    sign_in_as(@editor)
    post check_in_admin_box_office_path(@event), params: { ticket_id: @paid.id, count: 1 }
    assert_redirected_to admin_box_office_path(@event)
    assert_equal 1, @paid.reload.checked_in_count
    assert_match @paid.buyer_name, flash[:notice]
  end

  test "editor can check in a whole booking at once" do
    @paid.update!(quantity: 3)
    sign_in_as(@editor)
    post check_in_admin_box_office_path(@event), params: { ticket_id: @paid.id, count: 3 }
    assert_equal 3, @paid.reload.checked_in_count
  end

  test "check in is still allowed after the box office closes" do
    @event.update!(box_office_closed_manually: true)
    sign_in_as(@editor)
    post check_in_admin_box_office_path(@event), params: { ticket_id: @paid.id, count: 1 }
    assert_equal 1, @paid.reload.checked_in_count
  end

  test "check in is refused when the room is full" do
    @event.update!(capacity: 1)
    Ticket.create!(event: @event, buyer_name: "Walk Up", quantity: 1, amount_cents: 1000,
                   status: :reserved, checked_in_count: 1)
    sign_in_as(@editor)
    post check_in_admin_box_office_path(@event), params: { ticket_id: @paid.id, count: 1 }
    assert_equal 0, @paid.reload.checked_in_count
    assert_match(/room is full/, flash[:alert])
  end

  test "check in is refused when the booking is already fully checked in" do
    @paid.update!(checked_in_count: 1)
    sign_in_as(@editor)
    post check_in_admin_box_office_path(@event), params: { ticket_id: @paid.id, count: 1 }
    assert_equal 1, @paid.reload.checked_in_count
    assert_match(/already checked in/, flash[:alert])
  end

  test "check in cannot reach tickets for another event" do
    other = events(:published_event)
    sign_in_as(@editor)
    post check_in_admin_box_office_path(other), params: { ticket_id: @paid.id, count: 1 }
    assert_response :not_found
    assert_equal 0, @paid.reload.checked_in_count
  end

  test "viewer cannot check anyone in" do
    sign_in_as(@viewer)
    post check_in_admin_box_office_path(@event), params: { ticket_id: @paid.id, count: 1 }
    assert_redirected_to root_path
    assert_equal 0, @paid.reload.checked_in_count
  end

  # undo_check_in

  test "editor can undo a check in" do
    @paid.update!(checked_in_count: 1)
    sign_in_as(@editor)
    post undo_check_in_admin_box_office_path(@event), params: { ticket_id: @paid.id }
    assert_redirected_to admin_box_office_path(@event)
    assert_equal 0, @paid.reload.checked_in_count
  end

  # walk_up

  test "walk up sells a door booking and checks everyone in" do
    sign_in_as(@editor)
    assert_difference -> { @event.tickets.reserved.count }, 1 do
      post walk_up_admin_box_office_path(@event), params: { buyer_name: "Walk Up", quantity: 2 }
    end
    assert_redirected_to admin_box_office_path(@event)
    ticket = @event.tickets.reserved.order(:created_at).last
    assert_equal 2, ticket.quantity
    assert_equal 2, ticket.checked_in_count
    assert_equal @event.ticket_price_cents * 2, ticket.amount_cents
    assert_equal 2, @event.audience_count
  end

  test "walk up is refused when the box office is closed" do
    @event.update!(box_office_closed_manually: true)
    sign_in_as(@editor)
    assert_no_difference -> { @event.tickets.count } do
      post walk_up_admin_box_office_path(@event), params: { buyer_name: "Walk Up", quantity: 1 }
    end
    assert_match(/closed/, flash[:alert])
  end

  test "walk up is refused when there is not enough room" do
    @event.update!(capacity: 2)
    sign_in_as(@editor)
    assert_no_difference -> { @event.tickets.count } do
      post walk_up_admin_box_office_path(@event), params: { buyer_name: "Walk Up", quantity: 3 }
    end
    assert_match(/Only 2 spaces/, flash[:alert])
  end

  test "walk up requires a name" do
    sign_in_as(@editor)
    assert_no_difference -> { @event.tickets.count } do
      post walk_up_admin_box_office_path(@event), params: { buyer_name: "", quantity: 1 }
    end
    assert_match(/Buyer name/, flash[:alert])
  end

  # close / reopen

  test "editor can close the box office" do
    sign_in_as(@editor)
    patch close_admin_box_office_path(@event)
    assert_redirected_to admin_box_office_path(@event)
    assert @event.reload.box_office_closed_manually?
    assert_not @event.box_office_open?
  end

  test "editor can reopen a manually closed box office" do
    @event.update!(box_office_closed_manually: true)
    sign_in_as(@editor)
    patch reopen_admin_box_office_path(@event)
    assert_not @event.reload.box_office_closed_manually?
    assert @event.box_office_open?
  end

  # person_left / person_returned

  test "editor can tick the audience down when someone leaves" do
    @paid.update!(checked_in_count: 1)
    sign_in_as(@editor)
    patch person_left_admin_box_office_path(@event)
    assert_redirected_to admin_box_office_path(@event)
    assert_equal 0, @event.reload.audience_count
  end

  test "editor can tick the audience back up when someone returns" do
    @paid.update!(checked_in_count: 1)
    @event.update!(audience_left_count: 1)
    sign_in_as(@editor)
    patch person_returned_admin_box_office_path(@event)
    assert_equal 1, @event.reload.audience_count
  end

  test "someone returning is refused when the room is full" do
    @event.update!(capacity: 1)
    @paid.update!(checked_in_count: 1)
    Ticket.create!(event: @event, buyer_name: "Walk Up", quantity: 1, amount_cents: 1000,
                   status: :reserved, checked_in_count: 1)
    @event.update!(audience_left_count: 1)
    sign_in_as(@editor)
    patch person_returned_admin_box_office_path(@event)
    assert_equal 1, @event.reload.audience_left_count
    assert_match(/room is full/, flash[:alert])
  end

  test "viewer cannot change the headcount" do
    @paid.update!(checked_in_count: 1)
    sign_in_as(@viewer)
    patch person_left_admin_box_office_path(@event)
    assert_redirected_to root_path
    assert_equal 1, @event.reload.audience_count
  end
end
