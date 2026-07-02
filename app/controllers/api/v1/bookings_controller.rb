module Api
  module V1
    class BookingsController < ResourceController
      permits :title, :description, :starts_at, :ends_at, :status, :paid, :space_id, :user_id,
              :approved_at, :approved_by_id
    end
  end
end
