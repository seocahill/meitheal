# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = [ :active_support_logger ]
  config.dsn = Rails.application.credentials.dig(:sentry_dsn)
  config.traces_sample_rate = 0.3
  config.enabled_environments = %w[production]

  # Bots probe thencf.art for a WordPress install that does not exist, sending a
  # spoofed Client-Ip: 127.0.0.1 alongside a real X-Forwarded-For. Rails raises
  # from RemoteIp while logging the request. Rejecting these is correct
  # behaviour, not a defect, so keep them out of Sentry.
  config.excluded_exceptions += [ "ActionDispatch::RemoteIp::IpSpoofAttackError" ]
end
