ENV["RAILS_ENV"] ||= "test"
ENV["OBJC_DISABLE_INITIALIZE_FORK_SAFETY"] ||= "YES"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require "webmock/minitest"

# Block all real HTTP requests in tests — stubs must be used instead
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: "models.dev" # RubyLLM model registry refresh on boot
)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
