require "test_helper"

class TicketMailerTest < ActionMailer::TestCase
  setup do
    @ticket = tickets(:paid_ticket)
    @event = events(:ticketed_event)
  end

  test "confirmation is addressed to buyer" do
    email = TicketMailer.confirmation(@ticket)
    assert_equal [ @ticket.buyer_email ], email.to
  end

  test "confirmation subject includes event title" do
    email = TicketMailer.confirmation(@ticket)
    assert_includes email.subject, @event.title
  end

  test "confirmation body includes buyer name" do
    email = TicketMailer.confirmation(@ticket)
    decoded = email.text_part.decoded
    assert_includes decoded, @ticket.buyer_name
  end

  test "confirmation body includes event title" do
    email = TicketMailer.confirmation(@ticket)
    assert_includes email.body.encoded, @event.title
  end

  test "confirmation body includes quantity" do
    email = TicketMailer.confirmation(@ticket)
    assert_includes email.body.encoded, @ticket.quantity.to_s
  end

  test "confirmation body includes total paid" do
    email = TicketMailer.confirmation(@ticket)
    assert_includes email.body.encoded, "10.00"
  end
end
