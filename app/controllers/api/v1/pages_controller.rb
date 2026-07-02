module Api
  module V1
    class PagesController < ResourceController
      permits :title, :slug, :locale, :nav_location, :visibility, :content
    end
  end
end
