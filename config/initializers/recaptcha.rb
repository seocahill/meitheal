Recaptcha.configure do |config|
  config.site_key = Rails.application.credentials.dig(:recaptcha_site_key) || ENV.fetch("RECAPTCHA_SITE_KEY", "test-site-key")
  config.secret_key = Rails.application.credentials.dig(:recaptcha_secret_key) || ENV.fetch("RECAPTCHA_SECRET_KEY", "test-secret-key")
end
