require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:viewer)
    @event = events(:ticketed_event)
    # Owned by someone else and published, so these test events only surface
    # through the "My Tickets" card, never the viewer's own draft-events card.
    @other_owner = users(:editor)
  end

  test "shows the member's paid tickets for upcoming events" do
    Ticket.create!(event: @event, buyer_name: "Viewer", buyer_email: @user.email_address,
                   quantity: 2, amount_cents: 2000, status: :paid)
    sign_in_as(@user)
    get dashboard_path
    assert_response :success
    assert_match "My Tickets", response.body
    assert_match @event.title, response.body
  end

  test "matches the buyer email case-insensitively" do
    Ticket.create!(event: @event, buyer_name: "Viewer", buyer_email: @user.email_address.upcase,
                   quantity: 1, amount_cents: 1000, status: :paid)
    sign_in_as(@user)
    get dashboard_path
    assert_match @event.title, response.body
  end

  test "does not show tickets bought with a different email" do
    other_event = Event.create!(title: "Someone Else's Gig", starts_at: 1.week.from_now,
                                user: @other_owner, published: true, ticketing_enabled: true, ticket_price_cents: 1000)
    Ticket.create!(event: other_event, buyer_name: "Stranger", buyer_email: "stranger@example.com",
                   quantity: 1, amount_cents: 1000, status: :paid)
    sign_in_as(@user)
    get dashboard_path
    assert_no_match "Someone Else's Gig", response.body
  end

  test "does not show incomplete or pending tickets" do
    pending_event = Event.create!(title: "Unpaid Gig", starts_at: 1.week.from_now,
                                  user: @other_owner, published: true, ticketing_enabled: true, ticket_price_cents: 1000)
    Ticket.create!(event: pending_event, buyer_name: "Viewer", buyer_email: @user.email_address,
                   quantity: 1, amount_cents: 1000, status: :pending)
    sign_in_as(@user)
    get dashboard_path
    assert_no_match "Unpaid Gig", response.body
  end

  test "does not show tickets for past events" do
    past_event = Event.create!(title: "Last Year's Gig", starts_at: 1.week.ago,
                               user: @other_owner, published: true, ticketing_enabled: true, ticket_price_cents: 1000)
    Ticket.create!(event: past_event, buyer_name: "Viewer", buyer_email: @user.email_address,
                   quantity: 1, amount_cents: 1000, status: :paid)
    sign_in_as(@user)
    get dashboard_path
    assert_no_match "Last Year's Gig", response.body
  end
end
