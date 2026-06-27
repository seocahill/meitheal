# Preview at http://localhost:3000/rails/mailers/ticket_mailer/confirmation
class TicketMailerPreview < ActionMailer::Preview
  def confirmation
    ticket = Ticket.joins(:event).paid.last || Ticket.last
    TicketMailer.confirmation(ticket)
  end
end
