require "test_helper"

class EventTicketingTest < ActiveSupport::TestCase
  setup do
    @event = events(:ticketed_event)
  end

  # tickets_sold
  test "tickets_sold counts only paid ticket quantities" do
    assert_equal 1, @event.tickets_sold
  end

  # tickets_remaining
  test "tickets_remaining subtracts sold from capacity" do
    assert_equal 49, @event.tickets_remaining
  end

  test "tickets_remaining returns nil when no capacity set" do
    @event.update!(capacity: nil)
    assert_nil @event.tickets_remaining
  end

  test "tickets_remaining never goes below zero" do
    @event.update!(capacity: 0)
    assert_equal 0, @event.tickets_remaining
  end

  # sold_out?
  test "sold_out? is false when tickets remain" do
    assert_not @event.sold_out?
  end

  test "sold_out? is true when capacity is reached" do
    @event.update!(capacity: 1)
    assert @event.sold_out?
  end

  test "sold_out? is false when capacity is nil" do
    @event.update!(capacity: nil)
    assert_not @event.sold_out?
  end

  # ticketing_available?
  test "ticketing_available? is true for valid ticketed event" do
    assert @event.ticketing_available?
  end

  test "ticketing_available? is false when ticketing_enabled is false" do
    @event.update!(ticketing_enabled: false)
    assert_not @event.ticketing_available?
  end

  test "ticketing_available? is false when ticket_price_cents is nil" do
    @event.update!(ticket_price_cents: nil)
    assert_not @event.ticketing_available?
  end

  test "ticketing_available? is false when ticket_price_cents is zero" do
    @event.update!(ticket_price_cents: 0)
    assert_not @event.ticketing_available?
  end

  test "ticketing_available? is false when sold out" do
    @event.update!(capacity: 1)
    assert_not @event.ticketing_available?
  end

  test "ticketing_available? is false when sale has not started" do
    @event.update!(tickets_available_from: 1.day.from_now)
    assert_not @event.ticketing_available?
  end

  test "ticketing_available? is true when sale has started" do
    @event.update!(tickets_available_from: 1.day.ago)
    assert @event.ticketing_available?
  end

  test "ticketing_available? is true when tickets_available_from is nil" do
    @event.update!(tickets_available_from: nil)
    assert @event.ticketing_available?
  end
end
