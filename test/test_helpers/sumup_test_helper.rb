# Pins the SumUp credentials the service reads, so tests that stub SumUp's API
# do not depend on the environment they run in, and puts the environment back after.
module SumupTestHelper
  extend ActiveSupport::Concern

  API_KEY = "test-api-key".freeze
  MERCHANT_CODE = "TEST_MERCHANT".freeze
  HISTORY_URL = format(SumupCheckoutService::HISTORY_URL, MERCHANT_CODE).freeze
  ENV_KEYS = %w[SUMUP_API_KEY SUMUP_MERCHANT_CODE SUMUP_SANDBOX_API_KEY SUMUP_SANDBOX_MERCHANT_CODE].freeze

  included do
    setup do
      @sumup_env = ENV.to_h.slice(*ENV_KEYS)
      ENV["SUMUP_API_KEY"] = ENV["SUMUP_SANDBOX_API_KEY"] = API_KEY
      ENV["SUMUP_MERCHANT_CODE"] = ENV["SUMUP_SANDBOX_MERCHANT_CODE"] = MERCHANT_CODE
    end

    teardown do
      ENV_KEYS.each { |key| @sumup_env.key?(key) ? ENV[key] = @sumup_env[key] : ENV.delete(key) }
    end
  end
end
