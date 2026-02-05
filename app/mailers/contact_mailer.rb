class ContactMailer < ApplicationMailer
  def contact_message(email:, message:)
    @email = email
    @message = message
    admin_emails = User.where(role: :owner).pluck(:email_address)
    return if admin_emails.empty?

    mail(
      to: admin_emails,
      reply_to: email,
      subject: "Contact form message from #{email}"
    )
  end
end
