module Api
  module V1
    class SpacesController < ResourceController
      permits :name, :description, :capacity, :active, :component_of_id
    end
  end
end
