class ApplicationMailer < ActionMailer::Base
  default from: "noreply@thencf.art"
  layout "mailer"
  self.delivery_job = MailerDeliveryJob
end
