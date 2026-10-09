require_relative "boot"
require_relative "../lib/ip_spoof_attack_handler"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Meitheal
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # Allow iframes and video in the sanitize view helper
    config.action_view.sanitized_allowed_tags = Rails::HTML5::SafeListSanitizer.allowed_tags + [ "iframe", "video" ]
    config.action_view.sanitized_allowed_attributes = Rails::HTML5::SafeListSanitizer.allowed_attributes + [ "allow", "allowfullscreen", "frameborder", "loading", "referrerpolicy" ]

    config.i18n.available_locales = [ :en, :ga ]
    config.i18n.default_locale = :en

    # Bots send Client-IP: 127.0.0.1 to probe for localhost bypass. Rails
    # correctly detects this as spoofing (IpSpoofAttackError) but the error
    # propagates before ShowExceptions can render it, causing a 500. This
    # middleware wraps RemoteIp to return 400 Bad Request instead.
    config.middleware.insert_before(ActionDispatch::RemoteIp, IpSpoofAttackHandler)
  end
end
