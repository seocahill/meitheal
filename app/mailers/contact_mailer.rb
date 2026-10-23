class ContactMailer < ApplicationMailer
  COMPANY_EMAIL = "info@thencf.art"

  def contact_message(email:, message:)
    @email = email
    @message = message

    mail(
      to: COMPANY_EMAIL,
      reply_to: email,
      subject: "Contact form message from #{email}"
    )
  end
end
