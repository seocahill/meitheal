class TicketMailer < ApplicationMailer
  def confirmation(ticket)
    @ticket = ticket
    @event = ticket.event

    mail(
      to: ticket.buyer_email,
      subject: "Your ticket for #{@event.title}"
    )
  end
end
