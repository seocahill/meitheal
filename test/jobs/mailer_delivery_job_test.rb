require "test_helper"

class MailerDeliveryJobTest < ActiveJob::TestCase
  test "ApplicationMailer uses MailerDeliveryJob for delivery" do
    assert_equal MailerDeliveryJob, ApplicationMailer.delivery_job
  end

  test "retries on Net::ReadTimeout" do
    assert MailerDeliveryJob.rescue_handlers.any? { |handler| handler[0] == "Net::ReadTimeout" },
      "MailerDeliveryJob should retry on Net::ReadTimeout"
  end
end
