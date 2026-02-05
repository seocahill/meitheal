class UserMailer < ApplicationMailer
  def account_approved(user)
    @user = user
    mail(
      to: user.email_address,
      subject: "Your THENCF account has been approved!"
    )
  end
end
