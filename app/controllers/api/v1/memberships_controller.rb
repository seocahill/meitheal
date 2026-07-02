module Api
  module V1
    class MembershipsController < ResourceController
      permits :membership_type, :starts_on, :expires_on, :notes, :user_id
    end
  end
end
