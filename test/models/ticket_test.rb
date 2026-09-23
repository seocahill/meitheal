require "test_helper"

class TicketTest < ActiveSupport::TestCase
  setup do
    @event = events(:ticketed_event)
  end

  test "valid with required fields" do
    ticket = Ticket.new(
      event: @event,
      buyer_name: "Pádraig Ó Murchú",
      buyer_email: "padraig@example.com",
      quantity: 2,
      amount_cents: 1000
    )
    assert ticket.valid?
  end

  test "requires buyer_name" do
    ticket = Ticket.new(event: @event, buyer_email: "a@b.com", quantity: 1, amount_cents: 500)
    assert_not ticket.valid?
    assert_includes ticket.errors[:buyer_name], "can't be blank"
  end

  test "requires buyer_email" do
    ticket = Ticket.new(event: @event, buyer_name: "Test", quantity: 1, amount_cents: 500)
    assert_not ticket.valid?
    assert_includes ticket.errors[:buyer_email], "can't be blank"
  end

  test "reserved booking is valid without an email" do
    ticket = Ticket.new(event: @event, buyer_name: "Door Guest", quantity: 1,
                        amount_cents: 500, status: :reserved)
    assert ticket.valid?
  end

  test "reserved booking still rejects a malformed email" do
    ticket = Ticket.new(event: @event, buyer_name: "Door Guest", buyer_email: "notanemail",
                        quantity: 1, amount_cents: 500, status: :reserved)
    assert_not ticket.valid?
    assert ticket.errors[:buyer_email].present?
  end

  test "validates buyer_email format" do
    ticket = Ticket.new(event: @event, buyer_name: "Test", buyer_email: "notanemail", quantity: 1, amount_cents: 500)
    assert_not ticket.valid?
    assert ticket.errors[:buyer_email].present?
  end

  test "requires quantity greater than zero" do
    ticket = Ticket.new(event: @event, buyer_name: "Test", buyer_email: "a@b.com", quantity: 0, amount_cents: 500)
    assert_not ticket.valid?
  end

  test "requires amount_cents greater than zero" do
    ticket = Ticket.new(event: @event, buyer_name: "Test", buyer_email: "a@b.com", quantity: 1, amount_cents: 0)
    assert_not ticket.valid?
  end

  test "defaults to pending status" do
    ticket = Ticket.create!(
      event: @event,
      buyer_name: "Test",
      buyer_email: "a@b.com",
      quantity: 1,
      amount_cents: 500
    )
    assert ticket.pending?
  end

  test "status enum transitions" do
    ticket = Ticket.create!(
      event: @event,
      buyer_name: "Test",
      buyer_email: "a@b.com",
      quantity: 1,
      amount_cents: 500
    )
    ticket.paid!
    assert ticket.paid?
    ticket.failed!
    assert ticket.failed?
  end

  # check-in
  test "remaining_to_check_in is quantity minus checked in" do
    ticket = tickets(:paid_ticket)
    ticket.update!(quantity: 3, checked_in_count: 1)
    assert_equal 2, ticket.remaining_to_check_in
  end

  test "check_in! admits the requested number of people" do
    ticket = tickets(:paid_ticket)
    ticket.update!(quantity: 3)
    assert ticket.check_in!(2)
    assert_equal 2, ticket.reload.checked_in_count
  end

  test "check_in! refuses more people than the ticket covers" do
    ticket = tickets(:paid_ticket)
    ticket.update!(quantity: 2, checked_in_count: 1)
    assert_not ticket.check_in!(2)
    assert_equal 1, ticket.reload.checked_in_count
  end

  test "check_in! refuses when the room has no space" do
    ticket = tickets(:paid_ticket)
    ticket.update!(quantity: 3)
    @event.update!(capacity: 2)
    assert_not ticket.check_in!(3)
    assert_equal 0, ticket.reload.checked_in_count
  end

  test "check_in! refuses tickets that are not paid or reserved" do
    ticket = tickets(:pending_ticket)
    assert_not ticket.check_in!(1)
    assert_equal 0, ticket.reload.checked_in_count
  end

  test "undo_check_in! removes one checked-in person" do
    ticket = tickets(:paid_ticket)
    ticket.update!(quantity: 2, checked_in_count: 2)
    ticket.undo_check_in!
    assert_equal 1, ticket.reload.checked_in_count
  end

  test "undo_check_in! does nothing when nobody is checked in" do
    ticket = tickets(:paid_ticket)
    ticket.undo_check_in!
    assert_equal 0, ticket.reload.checked_in_count
  end

  test "checked_in_count cannot exceed quantity" do
    ticket = tickets(:paid_ticket)
    ticket.checked_in_count = 2
    assert_not ticket.valid?
  end
end
