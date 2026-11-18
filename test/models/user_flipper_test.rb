require "test_helper"

class UserFlipperTest < ActiveSupport::TestCase
  test "flag can be enabled for owners only" do
    Flipper.enable_group :f1_example, :owners

    assert Flipper.enabled?(:f1_example, users(:owner))
    refute Flipper.enabled?(:f1_example, users(:editor))
    refute Flipper.enabled?(:f1_example, users(:viewer))
  end

  test "flag can be enabled for a named user" do
    Flipper.enable_actor :f1_example, users(:viewer)

    assert Flipper.enabled?(:f1_example, users(:viewer))
    refute Flipper.enabled?(:f1_example, users(:owner))
  end

  test "flags are off by default" do
    refute Flipper.enabled?(:f1_example, users(:owner))
  end

  test "owners group ignores signed-out visitors" do
    Flipper.enable_group :f1_example, :owners

    refute Flipper.enabled?(:f1_example, nil)
  end
end
