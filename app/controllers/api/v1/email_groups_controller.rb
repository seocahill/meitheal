module Api
  module V1
    class EmailGroupsController < ResourceController
      permits :name, :local_part, :description, :active
    end
  end
end
