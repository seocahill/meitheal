class MailerDeliveryJob < ActionMailer::MailDeliveryJob
  retry_on Net::ReadTimeout, wait: :polynomially_longer, attempts: 3
end
