module Api
  module V1
    class AdminTodosController < ResourceController
      permits :title, :description, :completed, :due_date, :position, :priority,
              :source_id, :source_type
    end
  end
end
