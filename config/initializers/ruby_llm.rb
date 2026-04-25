RubyLLM.configure do |config|
  # Configure API keys from environment or credentials
  # config.openai_api_key = Rails.application.credentials.dig(:openai_api_key) || ENV["OPENAI_API_KEY"]
  # config.anthropic_api_key = Rails.application.credentials.dig(:anthropic_api_key) || ENV["ANTHROPIC_API_KEY"]
  config.mistral_api_key = Rails.application.credentials.dig(:mistral_api_key) || ENV["MISTRAL_API_KEY"]

  # Default model for chat (e.g. newsletter composition)
  config.default_model = "mistral-small-latest"

  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end

# Refresh model registry to pick up latest models
# Skip in test env and when the API key is absent (e.g. during Docker build)
RubyLLM.models.refresh! unless Rails.env.test? || ENV["MISTRAL_API_KEY"].blank?
