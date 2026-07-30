class Admin::TicketSalesController < Admin::BaseController
  before_action :require_editor
  before_action :set_event, only: [ :show, :add_booking ]

  def index
    @events = Event.joins(:tickets).distinct.order(starts_at: :desc)
  end

  def show
    @tickets = @event.tickets.order(created_at: :desc)
    @paid_count = @event.tickets_sold
    @reserved_count = @event.tickets_reserved
    @total_cents = @event.tickets.paid.sum(:amount_cents)
  end

  def add_booking
    quantity = params[:quantity].to_i
    quantity = 1 if quantity < 1

    if @event.capacity.present? && quantity > @event.tickets_remaining
      remaining = @event.tickets_remaining
      redirect_to admin_ticket_sale_path(@event),
        alert: "Only #{remaining} #{remaining == 1 ? "ticket" : "tickets"} remaining." and return
    end

    ticket = @event.tickets.new(
      buyer_name: params[:buyer_name].to_s.strip,
      buyer_email: params[:buyer_email].to_s.strip,
      quantity: quantity,
      amount_cents: @event.ticket_price_cents.to_i * quantity,
      status: :reserved
    )

    if ticket.save
      redirect_to admin_ticket_sale_path(@event), notice: "Booking added for #{ticket.buyer_name}."
    else
      redirect_to admin_ticket_sale_path(@event), alert: ticket.errors.full_messages.to_sentence
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end
end
