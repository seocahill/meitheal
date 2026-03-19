class Admin::BookingsController < ApplicationController
  include Pagy::Method
  before_action :require_editor
  before_action :set_booking, only: [ :toggle_paid ]

  def index
    scope = Booking.includes(:user, :space).order(starts_at: :desc)

    # Filter by status
    if params[:status].present?
      case params[:status]
      when "pending"
        scope = scope.pending
      when "confirmed"
        scope = scope.confirmed
      when "cancelled"
        scope = scope.where(status: :cancelled)
      end
    end

    # Filter by payment status
    if params[:paid].present?
      case params[:paid]
      when "unpaid"
        scope = scope.confirmed.unpaid
      when "paid"
        scope = scope.confirmed.where(paid: true)
      end
    end

    # Default to upcoming if no filters
    if params[:status].blank? && params[:paid].blank?
      scope = scope.upcoming
    end

    @pagy, @bookings = pagy(scope, items: 20)
  end

  def toggle_paid
    @booking.update!(paid: !@booking.paid)
    status_text = @booking.paid? ? "paid" : "unpaid"
    redirect_to admin_bookings_path, notice: "Booking marked as #{status_text}"
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end
end
