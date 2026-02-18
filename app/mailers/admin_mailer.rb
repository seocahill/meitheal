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
end
