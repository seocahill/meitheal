class PagesController < ApplicationController
  allow_unauthenticated_access

  def show
    @page = find_page
  end

  private

  def find_page
    page = Page.find_by!(slug: params[:slug])

    # Resume session to get current user (if any)
    authenticated?

    # Visibility checks
    case page.visibility
    when "draft"
      # Only editors can view drafts
      raise ActiveRecord::RecordNotFound unless current_user_can_edit?
    when "members_only"
      # Only authenticated users can view members-only pages
      raise ActiveRecord::RecordNotFound unless Current.user.present?
    end
    # "published" pages are visible to everyone

    page
  end
end
