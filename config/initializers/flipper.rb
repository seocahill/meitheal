Rails.application.configure do
  # Use the in-memory adapter in tests; state resets between tests.
  config.flipper.test_help = true
end

# Flags are off for everyone until enabled. To dark-launch for owners:
#   Flipper.enable_group(:f12_example, :owners)
Flipper.register(:owners) do |actor|
  actor.respond_to?(:owner?) && actor.owner?
end
