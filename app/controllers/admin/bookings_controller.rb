class Admin::BookingsController < Admin::BaseController
  include Pagy::Method

  # Everything the list can be filtered by, kept when moving between the list and a booking's pages.
  LIST_FILTERS = %i[status paid overdue when space_id q period from to page].freeze

  before_action :require_editor
  before_action :set_booking, only: [ :mark_unpaid ]

  def index
    scope = Booking.includes(:user, :space)
    scope = scope.where(space_id: params[:space_id]) if params[:space_id].present?
    scope = search(scope, params[:q]) if params[:q].present?
    @date_filter = DateRangeFilter.new(params)
    scope = scope.starting_within(@date_filter.range)

    scope = case params[:status]
    when "pending"   then scope.pending
    when "confirmed" then scope.confirmed
    when "cancelled" then scope.where(status: :cancelled)
    else scope
    end

    scope = if params[:overdue].present?
      scope.confirmed.unpaid.overdue
    elsif params[:paid] == "unpaid"
      scope.confirmed.unpaid
    elsif params[:paid] == "paid"
      scope.confirmed.where(paid: true)
    else
      scope
    end

    # Unfiltered, the list is what is coming up. Any status or payment filter looks at everything.
    timeframe = params[:when].presence || (filtered? ? "all" : "upcoming")
    scope = case timeframe
    when "upcoming" then scope.where("bookings.starts_at > ?", Time.current)
    when "past"     then scope.where("bookings.starts_at <= ?", Time.current)
    else scope
    end

    # Longest outstanding first when chasing payment, otherwise soonest first for what is
    # coming up and most recent first for history.
    scope = if params[:paid] == "unpaid" || params[:overdue].present? || timeframe == "upcoming"
      scope.order(:starts_at)
    else
      scope.order(starts_at: :desc)
    end

    @counts = {
      unpaid: Booking.confirmed.unpaid.count,
      overdue: Booking.confirmed.unpaid.overdue.count,
      pending: Booking.pending.count
    }
    @spaces = Space.order(:name)
    @pagy, @bookings = pagy(scope, limit: 20)
  end

  # Corrects a payment recorded in error. Payments are recorded from the booking's payment form.
  def mark_unpaid
    @booking.mark_unpaid!
    redirect_to admin_bookings_path(list_filters), notice: "#{@booking.title} marked unpaid."
  end

  private

  def set_booking
    @booking = Booking.find(params[:id])
  end

  def filtered?
    params[:status].present? || params[:paid].present? || params[:overdue].present? || @date_filter.active?
  end

  # Keep the current filters and search when returning to the list.
  def list_filters
    params.permit(*LIST_FILTERS).to_h.compact_blank
  end

  def search(scope, term)
    pattern = "%#{Booking.sanitize_sql_like(term.downcase)}%"
    user_ids = User.left_joins(:profile)
                   .where("LOWER(users.email_address) LIKE :t OR LOWER(profiles.name) LIKE :t", t: pattern)
                   .select(:id)
    scope.where("LOWER(bookings.title) LIKE ?", pattern).or(scope.where(user_id: user_ids))
  end
end
