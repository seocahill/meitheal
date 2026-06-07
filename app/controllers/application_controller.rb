class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :set_locale

  private

  def set_locale(&action)
    locale = params[:locale].presence || session[:locale] || browser_preferred_locale || I18n.default_locale.to_s
    locale = I18n.default_locale.to_s unless I18n.available_locales.map(&:to_s).include?(locale)
    session[:locale] = locale
    I18n.with_locale(locale, &action)
  end

  def browser_preferred_locale
    available = I18n.available_locales.map(&:to_s)
    request.env["HTTP_ACCEPT_LANGUAGE"]
      &.scan(/[a-z]{2,3}(?:-[A-Za-z]{2,4})?/i)
      &.map { |tag| tag.split("-").first.downcase }
      &.find { |lang| available.include?(lang) }
  end

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Thredded expects current_user method
  def current_user
    Current.user
  end
  helper_method :current_user
end
