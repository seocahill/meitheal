class HomeController < ApplicationController
  allow_unauthenticated_access
  layout "homepage"

  def index
    if authenticated?
      redirect_to dashboard_path
    else
      @upcoming_events = Event.published.upcoming.limit(3)
    end
  end
end
