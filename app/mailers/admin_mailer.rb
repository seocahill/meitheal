class AdminMailer < ApplicationMailer
  def new_user_pending_approval(user)
    @user = user
    admin_emails = User.where(role: :owner).pluck(:email_address)
    return if admin_emails.empty?

    mail(
      to: admin_emails,
      subject: "New user pending approval: #{user.profile&.name || user.email_address}"
    )
  end

  def new_funding_opportunity_pending_approval(funding_opportunity)
    @funding_opportunity = funding_opportunity
    admin_emails = User.where(role: :owner).pluck(:email_address)
    return if admin_emails.empty?

    mail(
      to: admin_emails,
      subject: "Funding opportunity pending approval: #{funding_opportunity.title}"
    )
  end

  def daily_pending_summary
    admin_emails = User.where(role: :owner).pluck(:email_address)
    return if admin_emails.empty?

    @pending_users = User.where(approved: false)
    @pending_funding_opportunities = FundingOpportunity.pending_approval
    @pending_proposals = Proposal.pending_review
    @pending_bookings = Booking.pending
    @draft_events = Event.draft
    @unpaid_bookings = Booking.confirmed.unpaid.includes(:user, :space)

    return if [ @pending_users, @pending_funding_opportunities, @pending_proposals,
                @pending_bookings, @draft_events, @unpaid_bookings ].all?(&:none?)

    mail(
      to: admin_emails,
      subject: "Daily summary: items awaiting your action"
    )
  end
end
