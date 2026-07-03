module Api
  module V1
    class NewslettersController < ResourceController
      permits :subject, :status, :sent_at, :brevo_campaign_id, :chat_id, :content
    end
  end
end
