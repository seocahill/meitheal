class HomeController < ApplicationController
  allow_unauthenticated_access
  layout "homepage"

  def index
    @upcoming_events = Event.published.upcoming.limit(3)
  end
end
