module Api
  module V1
    class ProposalsController < ResourceController
      permits :title, :description, :amount_requested, :organizer_fee, :status, :submission_deadline,
              :submitted_at, :reviewed_at, :admin_notes, :funding_opportunity_id, :user_id
    end
  end
end
