class LocalesController < ApplicationController
  allow_unauthenticated_access

  # GET /locale/:locale
  # set_locale around_action already persists params[:locale] to session.
  # We just redirect back to wherever the user came from.
  def update
    redirect_back_or_to root_path, allow_other_host: false
  end
end
