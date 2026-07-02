module Api
  module V1
    class TicketsController < ResourceController
      permits :buyer_name, :buyer_email, :quantity, :amount_cents, :status, :event_id,
              :sumup_checkout_id, :sumup_transaction_id
    end
  end
end
