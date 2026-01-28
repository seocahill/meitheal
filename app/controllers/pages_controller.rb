class PagesController < ApplicationController
  allow_unauthenticated_access

  def show
    @page = find_page
  end

  private

  def find_page
    page = Page.find_by!(slug: params[:slug])

    # Allow editors to view unpublished pages
    # Must call authenticated? to resume session when using allow_unauthenticated_access
    authenticated?
    if !page.published? && !current_user_can_edit?
      raise ActiveRecord::RecordNotFound
    end

    page
  end
end
