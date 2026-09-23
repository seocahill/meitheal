# Mobile door view for the box office on the night: find bookings and check
# people in, sell walk-ups, and keep a live headcount against capacity.
class Admin::BoxOfficesController < Admin::BaseController
  before_action :require_editor
  before_action :set_event
  before_action :set_ticket, only: [ :check_in, :undo_check_in ]

  def show
    @query = params[:q].to_s.strip
    @tickets = @event.search_admitted_tickets(@query)
  end

  def check_in
    count = params[:count].to_i
    if @ticket.check_in!(count)
      redirect_to admin_box_office_path(@event), notice: "Checked in #{count} for #{@ticket.buyer_name}."
    elsif @ticket.fully_checked_in?
      redirect_to admin_box_office_path(@event), alert: "#{@ticket.buyer_name} is already checked in."
    else
      redirect_to admin_box_office_path(@event), alert: not_enough_room_message
    end
  end

  def undo_check_in
    @ticket.undo_check_in!
    redirect_to admin_box_office_path(@event), notice: "Undid a check in for #{@ticket.buyer_name}."
  end

  def walk_up
    quantity = [ params[:quantity].to_i, 1 ].max

    unless @event.box_office_open?
      redirect_to admin_box_office_path(@event), alert: "The box office is closed." and return
    end

    space = @event.audience_space_left
    if space && quantity > space
      redirect_to admin_box_office_path(@event), alert: not_enough_room_message and return
    end

    ticket = @event.build_door_booking(buyer_name: params[:buyer_name], quantity: quantity)
    ticket.checked_in_count = quantity

    if ticket.save
      redirect_to admin_box_office_path(@event), notice: "Sold #{quantity} at the door to #{ticket.buyer_name}."
    else
      redirect_to admin_box_office_path(@event), alert: ticket.errors.full_messages.to_sentence
    end
  end

  def close
    @event.update!(box_office_closed_manually: true)
    redirect_to admin_box_office_path(@event), notice: "Box office closed."
  end

  def reopen
    @event.update!(box_office_closed_manually: false)
    redirect_to admin_box_office_path(@event), notice: "Box office reopened."
  end

  def person_left
    @event.record_audience_left!
    redirect_to admin_box_office_path(@event)
  end

  def person_returned
    if @event.audience_full?
      redirect_to admin_box_office_path(@event), alert: not_enough_room_message
    else
      @event.record_audience_returned!
      redirect_to admin_box_office_path(@event)
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def set_ticket
    @ticket = @event.tickets.find(params[:ticket_id])
  end

  def not_enough_room_message
    space = @event.audience_space_left
    if space == 0
      "The room is full."
    else
      "Only #{space} #{space == 1 ? "space" : "spaces"} left in the room."
    end
  end
end
