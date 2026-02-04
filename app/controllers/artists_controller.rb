class ArtistsController < ApplicationController
  allow_unauthenticated_access

  def index
    @profiles = Profile.where(visible: true).order(:name)
  end
end
