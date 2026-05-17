class EventTicketsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create_checkout, :complete ]
  before_action :set_event

  def new
    unless @event.ticketing_available?
      redirect_to event_path(@event), alert: "Tickets are not currently available for this event." and return
    end
  end

  def create_checkout
    unless @event.ticketing_available?
      return render json: { error: "Tickets are not available for this event." }, status: :unprocessable_entity
    end

    quantity = params[:quantity].to_i
    buyer_name = params[:buyer_name].to_s.strip
    buyer_email = params[:buyer_email].to_s.strip

    if quantity < 1
      return render json: { error: "Quantity must be at least 1." }, status: :unprocessable_entity
    end

    if buyer_name.blank? || buyer_email.blank?
      return render json: { error: "Name and email are required." }, status: :unprocessable_entity
    end

    if @event.capacity.present? && quantity > @event.tickets_remaining
      remaining = @event.tickets_remaining
      return render json: { error: "Only #{remaining} #{remaining == 1 ? "ticket" : "tickets"} remaining." }, status: :unprocessable_entity
    end

    amount_cents = @event.ticket_price_cents * quantity
    checkout_reference = "ticket-#{@event.id}-#{SecureRandom.hex(6)}"
    description = "#{@event.title} – #{quantity} #{quantity == 1 ? "ticket" : "tickets"}"

    begin
      checkout = SumupCheckoutService.new.create_checkout(
        amount_cents: amount_cents,
        description: description,
        checkout_reference: checkout_reference,
        return_url: complete_event_tickets_url(@event)
      )

      ticket = Ticket.create!(
        event: @event,
        buyer_name: buyer_name,
        buyer_email: buyer_email,
        quantity: quantity,
        amount_cents: amount_cents,
        status: :pending,
        sumup_checkout_id: checkout["id"]
      )

      render json: { checkout_id: checkout["id"] }
    rescue SumupCheckoutService::CheckoutError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error("Ticket checkout failed: #{e.class}: #{e.message}")
      render json: { error: "Payment service unavailable. Please try again later." }, status: :service_unavailable
    end
  end

  def complete
    checkout_id = params[:checkout_id]

    unless checkout_id.present?
      redirect_to event_path(@event) and return
    end

    ticket = @event.tickets.find_by(sumup_checkout_id: checkout_id)

    unless ticket
      redirect_to event_path(@event), alert: "Ticket not found." and return
    end

    begin
      checkout = SumupCheckoutService.new.get_checkout(checkout_id)

      if checkout["status"] == "PAID"
        ticket.update!(
          status: :paid,
          sumup_transaction_id: checkout["transaction_id"]
        )
        TicketMailer.confirmation(ticket).deliver_later
        redirect_to event_path(@event), notice: "Payment successful! Your ticket confirmation has been sent to #{ticket.buyer_email}."
      else
        ticket.update!(status: :failed)
        redirect_to event_path(@event), alert: "Payment was not completed. Please try again."
      end
    rescue => e
      Rails.logger.error("Ticket checkout verification failed: #{e.message}")
      redirect_to event_path(@event), alert: "Unable to verify payment. Please contact us if you were charged."
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
