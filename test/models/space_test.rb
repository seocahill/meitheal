require "test_helper"

class SpaceTest < ActiveSupport::TestCase
  test "valid space with required attributes" do
    space = Space.new(name: "Main Hall", capacity: 50)
    assert space.valid?
  end

  test "requires name" do
    space = Space.new(capacity: 50)
    assert_not space.valid?
    assert_includes space.errors[:name], "can't be blank"
  end

  test "scope active returns only active spaces" do
    active = Space.create!(name: "Active Room", active: true)
    inactive = Space.create!(name: "Inactive Room", active: false)

    assert_includes Space.active, active
    assert_not_includes Space.active, inactive
  end
end
