module Api
  module V1
    class ProfilesController < ResourceController
      permits :name, :bio, :location, :skills, :website, :visible, :public_gallery, :user_id
    end
  end
end
