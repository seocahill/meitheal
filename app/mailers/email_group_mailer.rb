class EmailGroupMailer < ApplicationMailer
  def forward_email(group:, archived_email:, recipient:)
    @group = group
    @archived_email = archived_email
    @recipient = recipient

    mail(
      to: recipient.email_address,
      from: group.email_address,
      reply_to: archived_email.from_address,
      subject: "[#{group.name}] #{archived_email.subject}"
    )
  end
end
