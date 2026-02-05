class DashboardController < ApplicationController
  def index
    @user = Current.user

    # Items relevant to all members
    @my_bookings = @user.bookings.upcoming.includes(:space).limit(5)
    @my_proposals = @user.proposals.includes(:funding_opportunity).order(updated_at: :desc).limit(5)
    @upcoming_events = Event.published.upcoming.limit(5)
    @open_funding = FundingOpportunity.upcoming.limit(5)

    # Editor items
    if @user.can_edit?
      @pending_bookings = Booking.pending.upcoming.includes(:space, :user).limit(10)
      @draft_events = Event.draft.includes(:user).order(updated_at: :desc).limit(10)
      @draft_newsletters = Newsletter.draft.order(updated_at: :desc).limit(5)
    end

    # Owner/admin items
    if @user.can_manage?
      @pending_users = User.where(approved: false).includes(:profile).order(created_at: :desc).limit(10)
      @pending_proposals = Proposal.submitted.includes(:user, :funding_opportunity).order(submitted_at: :desc).limit(10)
      @admin_todos = AdminTodo.pending.default_order.limit(10)
    end
  end
end
