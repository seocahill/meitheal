# Settles a booking with a bank transfer, a SumUp transaction, a payment already on file, or a new offline payment.
class Admin::BookingPaymentsController < Admin::BaseController
  before_action :require_editor
  before_action :set_booking

  def new
    @candidates = @booking.payment_candidates.order(paid_on: :desc, created_at: :desc)
    @bank_transactions = @booking.bank_candidates
    @sumup_transactions = @booking.sumup_candidates
  end

  def create
    if params[:payment_id].present?
      @booking.attach_payment!(Payment.find(params[:payment_id]))
    elsif params[:bank_transaction_id].present?
      @booking.attach_bank_transaction!(BankTransaction.find(params[:bank_transaction_id]))
    elsif params[:sumup_transaction_id].present?
      @booking.attach_sumup_transaction!(SumupTransaction.find(params[:sumup_transaction_id]))
    else
      return back_to_form("Choose cash, bank transfer or other.") unless Payment::OFFLINE_METHODS.include?(payment_params[:payment_method])

      @booking.record_payment!(**payment_params.to_h.symbolize_keys)
    end
    redirect_to admin_bookings_path(list_filters), notice: "#{@booking.title} marked paid."
  rescue ActiveRecord::RecordNotFound
    back_to_form("That payment is no longer available.")
  rescue ActiveRecord::RecordInvalid => e
    back_to_form("Could not record payment: #{e.record.errors.full_messages.to_sentence}.")
  end

  private

  def set_booking
    @booking = Booking.confirmed.find(params[:booking_id])
  end

  def back_to_form(alert)
    redirect_to new_admin_booking_payment_path(@booking, list_filters), alert: alert
  end

  def list_filters
    params.permit(*Admin::BookingsController::LIST_FILTERS).to_h.compact_blank
  end

  def payment_params
    params.require(:payment).permit(:amount_euro, :paid_on, :payment_method, :notes)
  end
end
