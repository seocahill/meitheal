module Api
  module V1
    class PostsController < ResourceController
      permits :title, :slug, :excerpt, :post_type, :published, :published_at, :user_id, :body
    end
  end
end
