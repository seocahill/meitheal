class Admin::TicketSalesController < Admin::BaseController
  before_action :require_editor

  def index
    @events = Event.joins(:tickets).distinct.order(starts_at: :desc)
  end

  def show
    @event = Event.find(params[:id])
    @tickets = @event.tickets.order(created_at: :desc)
    @paid_count = @event.tickets_sold
    @total_cents = @event.tickets.paid.sum(:amount_cents)
  end
end
