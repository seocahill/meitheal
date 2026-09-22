require "test_helper"

class EventBoxOfficeTest < ActiveSupport::TestCase
  setup do
    @event = events(:ticketed_event)
    @paid = tickets(:paid_ticket)
  end

  def reserve(quantity, checked_in: 0)
    Ticket.create!(event: @event, buyer_name: "Door Guest", quantity: quantity,
                   amount_cents: 1000 * quantity, status: :reserved, checked_in_count: checked_in)
  end

  # audience_count
  test "audience_count is zero before anyone is checked in" do
    assert_equal 0, @event.audience_count
  end

  test "audience_count sums checked-in paid and reserved tickets" do
    @paid.update!(checked_in_count: 1)
    reserve(3, checked_in: 2)
    assert_equal 3, @event.audience_count
  end

  test "audience_count ignores pending tickets" do
    tickets(:pending_ticket).update_columns(checked_in_count: 2)
    assert_equal 0, @event.audience_count
  end

  test "audience_count subtracts people who left" do
    reserve(5, checked_in: 5)
    @event.update!(audience_left_count: 2)
    assert_equal 3, @event.audience_count
  end

  # audience_space_left / audience_full?
  test "audience_space_left is capacity minus audience" do
    reserve(5, checked_in: 5)
    assert_equal 45, @event.audience_space_left
  end

  test "audience_full? when audience reaches capacity" do
    @event.update!(capacity: 3)
    reserve(3, checked_in: 3)
    assert @event.audience_full?
  end

  test "audience is not full once someone leaves" do
    @event.update!(capacity: 3)
    reserve(3, checked_in: 3)
    @event.record_audience_left!
    assert_not @event.audience_full?
  end

  test "audience is never full without a capacity" do
    @event.update!(capacity: nil)
    assert_not @event.audience_full?
    assert_nil @event.audience_space_left
  end

  # record_audience_left! / record_audience_returned!
  test "record_audience_left! cannot take the audience below zero" do
    @event.record_audience_left!
    assert_equal 0, @event.reload.audience_left_count
  end

  test "record_audience_returned! undoes a leaver" do
    reserve(2, checked_in: 2)
    @event.record_audience_left!
    @event.record_audience_returned!
    assert_equal 2, @event.audience_count
  end

  test "record_audience_returned! does nothing when nobody has left" do
    @event.record_audience_returned!
    assert_equal 0, @event.reload.audience_left_count
  end

  test "record_audience_returned! refuses when the room is full" do
    @event.update!(capacity: 2)
    reserve(3, checked_in: 3)
    @event.record_audience_left!
    assert_not @event.record_audience_returned!
    assert_equal 1, @event.reload.audience_left_count
  end

  # box office
  test "box office closes 30 minutes before the show starts by default" do
    assert_equal @event.starts_at - 30.minutes, @event.box_office_closes_at
  end

  test "box office is open before the closing time" do
    assert @event.box_office_open?
    assert_nil @event.box_office_closed_reason
  end

  test "box office is closed from 30 minutes before the show" do
    travel_to(@event.starts_at - 29.minutes) do
      assert_not @event.box_office_open?
      assert_equal :time, @event.box_office_closed_reason
    end
  end

  test "box office is closed when closed manually" do
    @event.update!(box_office_closed_manually: true)
    assert_not @event.box_office_open?
    assert_equal :manual, @event.box_office_closed_reason
  end

  test "box office is closed when the audience is full" do
    @event.update!(capacity: 2)
    reserve(2, checked_in: 2)
    assert_not @event.box_office_open?
    assert_equal :full, @event.box_office_closed_reason
  end

  test "online ticketing is unavailable once the box office closes" do
    @event.update!(box_office_closed_manually: true)
    assert_not @event.ticketing_available?
  end

  test "online ticketing is unavailable 30 minutes before the show" do
    travel_to(@event.starts_at - 10.minutes) do
      assert_not @event.ticketing_available?
    end
  end

  # search_admitted_tickets
  test "search_admitted_tickets returns paid and reserved tickets sorted by name" do
    reserve(1).update!(buyer_name: "Aoife Walsh")
    names = @event.search_admitted_tickets(nil).map(&:buyer_name)
    assert_equal [ "Aoife Walsh", "Siobhán Ní Fhaoláin" ], names
  end

  test "search_admitted_tickets matches names ignoring case and fadas" do
    reserve(1).update!(buyer_name: "Aoife Walsh")
    assert_equal [ @paid ], @event.search_admitted_tickets("siobhan")
    assert_equal [ @paid ], @event.search_admitted_tickets("FHAOL")
  end

  test "search_admitted_tickets matches email" do
    assert_equal [ @paid ], @event.search_admitted_tickets("siobhan@example")
  end

  test "search_admitted_tickets excludes pending tickets" do
    assert_empty @event.search_admitted_tickets("padraig")
  end
end
