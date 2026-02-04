class EventsController < ApplicationController
  include Pagy::Method

  allow_unauthenticated_access only: [ :index, :show ]
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :publish, :unpublish ]
  before_action :require_editable, only: [ :edit, :update, :destroy ]
  before_action :require_publishable, only: [ :publish, :unpublish ]

  def index
    @pagy, @events = pagy(Event.published.with_attached_image, items: 5)
  end

  def show
    unless @event.published? || can_view_draft?(@event)
      redirect_to events_path, alert: "Event not found."
    end
  end

  def new
    @event = Event.new
  end

  def create
    @event = Current.user.events.build(event_params)
    if @event.save
      redirect_to @event, notice: "Event created. It will be visible after an admin publishes it."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Viewers can't change published status even on their own events
    filtered_params = event_params
    unless Current.user.can_edit?
      filtered_params = filtered_params.except(:published)
    end

    if @event.update(filtered_params)
      redirect_to @event, notice: "Event updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to events_path, notice: "Event deleted."
  end

  def publish
    @event.update!(published: true)
    redirect_to @event, notice: "Event published."
  end

  def unpublish
    @event.update!(published: false)
    redirect_to @event, notice: "Event unpublished."
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :title, :starts_at, :ends_at, :doors_at, :description, :bio,
      :links, :ticket_price_cents, :ticket_url, :capacity,
      :venue_name, :venue_address, :published, :image
    )
  end

  def can_view_draft?(event)
    # Must call authenticated? to ensure session is resumed for unauthenticated routes
    authenticated? && (event.user == Current.user || Current.user.can_edit?)
  end

  def require_editable
    unless @event.editable_by?(Current.user)
      redirect_to root_path, alert: "You don't have permission to do that."
    end
  end

  def require_publishable
    unless @event.publishable_by?(Current.user)
      redirect_to root_path, alert: "You don't have permission to do that."
    end
  end
end
