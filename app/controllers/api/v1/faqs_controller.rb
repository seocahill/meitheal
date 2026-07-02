module Api
  module V1
    class FaqsController < ResourceController
      permits :question, :answer, :order, :active
    end
  end
end
