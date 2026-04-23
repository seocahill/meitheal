require "test_helper"
require "yaml"
require "erb"

class CableConfigurationTest < ActiveSupport::TestCase
  # Regression test for THENCF-4/5: Action Cable was configured to use the
  # redis adapter in production but the redis gem is not in the bundle.
  # The app uses solid_cable (backed by SQLite) instead.
  test "production cable adapter is solid_cable" do
    raw = File.read(Rails.root.join("config/cable.yml"))
    config = YAML.safe_load(ERB.new(raw).result)
    adapter = config.dig("production", "adapter")
    assert_equal "solid_cable", adapter,
      "config/cable.yml production adapter must be 'solid_cable' — the redis gem is not in the bundle"
  end
end
