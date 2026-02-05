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
end
