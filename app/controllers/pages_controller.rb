class PagesController < ApplicationController
  allow_unauthenticated_access

  def show
    @page = find_page
  end

  private

  def find_page
    page = Page.find_by(slug: params[:slug], locale: I18n.locale.to_s) ||
           Page.find_by!(slug: params[:slug], locale: "en")

    # Visibility checks
    case page.visibility
    when "draft"
      raise ActiveRecord::RecordNotFound unless current_user_can_edit?
    when "members_only"
      raise ActiveRecord::RecordNotFound unless Current.user.present?
    end

    page
  end
end
