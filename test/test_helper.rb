ENV["RAILS_ENV"] ||= "test"
ENV["MISTRAL_API_KEY"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require "webmock/minitest"

# Block all real HTTP requests in tests — stubs must be used instead
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: "models.dev" # RubyLLM model registry refresh on boot
)

# Fake SumUp credentials so service doesn't raise before hitting stubbed HTTP
ENV["SUMUP_API_KEY"] ||= "test-api-key"
ENV["SUMUP_MERCHANT_CODE"] ||= "TEST_MERCHANT"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
