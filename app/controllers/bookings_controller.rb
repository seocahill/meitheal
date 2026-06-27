class BookingsController < ApplicationController
  allow_unauthenticated_access only: [ :calendar ]
  before_action :set_booking, only: [ :edit, :update, :destroy, :confirm, :cancel, :mark_as_paid ]
  before_action :require_editable, only: [ :edit, :update, :destroy ]
  before_action :require_editor, only: [ :confirm, :mark_as_paid ]
  before_action :require_cancellable, only: [ :cancel ]
  before_action :require_active_membership, only: [ :new, :create ]

  def calendar
    @month = begin
      params[:month].present? ? Date.strptime(params[:month], "%Y-%m") : Date.current.beginning_of_month
    rescue ArgumentError, Date::Error
      Date.current.beginning_of_month
    end
    # Show both pending and confirmed bookings
    @bookings = Booking.where(status: [ :pending, :confirmed ])
      .where("starts_at < ? AND ends_at > ?", @month.end_of_month.end_of_day, @month.beginning_of_month.beginning_of_day)
      .includes(:space, :user)
      .order(:starts_at)
    @spaces = Space.active.order(:name)

    # For admin: show pending bookings needing confirmation
    if authenticated? && Current.user.can_edit?
      @pending_bookings = Booking.pending.upcoming.includes(:space, :user).limit(10)
    end
  end

  def new
    @booking = Booking.new(starts_at: Time.current.noon, ends_at: Time.current.noon + 2.hours)
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
    @booking.update!(status: :confirmed, approved_by: Current.user, approved_at: Time.current)
    redirect_to calendar_path, notice: "Booking confirmed."
  end

  def cancel
    @booking.cancelled!
    redirect_to calendar_path, notice: "Booking cancelled."
  end

  def mark_as_paid
    @booking.update!(paid: true)
    redirect_to calendar_path, notice: "Booking marked as paid"
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
