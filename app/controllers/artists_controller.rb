class ArtistsController < ApplicationController
  allow_unauthenticated_access

  def index
    @profiles = Profile.in_public_gallery.order(:name)
  end
end
