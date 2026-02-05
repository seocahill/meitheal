class BookingsController < ApplicationController
  allow_unauthenticated_access only: [ :calendar ]
  before_action :set_booking, only: [ :edit, :update, :destroy, :confirm, :cancel ]
  before_action :require_editable, only: [ :edit, :update, :destroy ]
  before_action :require_editor, only: [ :confirm ]
  before_action :require_cancellable, only: [ :cancel ]
  before_action :require_active_membership, only: [ :new, :create ]

  def calendar
    @month = params[:month] ? Date.parse(params[:month] + "-01") : Date.current.beginning_of_month
    # Show both pending and confirmed bookings
    @bookings = Booking.where(status: [ :pending, :confirmed ])
      .where("starts_at >= ? AND starts_at < ?", @month.beginning_of_month, @month.end_of_month.end_of_day)
      .includes(:space, :user)
      .order(:starts_at)
    @spaces = Space.active.order(:name)

    # For admin: show pending bookings needing confirmation
    if authenticated? && Current.user.can_edit?
      @pending_bookings = Booking.pending.upcoming.includes(:space, :user).limit(10)
    end
  end

  def new
    @booking = Booking.new
    @spaces = Space.active.order(:name)
  end

  def create
    @booking = Current.user.bookings.build(booking_params)
    if @booking.save
      redirect_to calendar_path, notice: "Booking request submitted. An admin will confirm it."
    else
      @spaces = Space.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @spaces = Space.active.order(:name)
  end

  def update
    if @booking.update(booking_params)
      redirect_to calendar_path, notice: "Booking updated."
    else
      @spaces = Space.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @booking.destroy
    redirect_to calendar_path, notice: "Booking deleted."
  end

  def confirm
    @booking.confirmed!
    redirect_to calendar_path, notice: "Booking confirmed."
  end

  def cancel
    @booking.cancelled!
    redirect_to calendar_path, notice: "Booking cancelled."
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(:space_id, :title, :description, :starts_at, :ends_at, :agree_booking_rules, :agree_ethics)
  end

  def require_editable
    unless @booking.editable_by?(Current.user)
      redirect_to root_path, alert: "You don't have permission to do that."
    end
  end

  def require_cancellable
    unless @booking.editable_by?(Current.user)
      redirect_to root_path, alert: "You don't have permission to do that."
    end
  end

  def require_active_membership
    unless Current.user&.has_active_membership?
      redirect_to calendar_path, alert: "You need an active membership to book spaces. Please renew your membership."
    end
  end
end
