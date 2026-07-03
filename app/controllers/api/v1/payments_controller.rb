module Api
  module V1
    class PaymentsController < ResourceController
      permits :amount_cents, :description, :notes, :paid_on, :payment_method, :purpose, :status,
              :user_email, :user_name, :membership_id, :pending_membership_type,
              :sumup_checkout_id, :sumup_transaction_id
    end
  end
end
