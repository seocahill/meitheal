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

  test "linked_space_ids returns parent ID for component space" do
    front_room = spaces(:front_room)
    whole_building = spaces(:whole_building)

    assert_equal [whole_building.id], front_room.linked_space_ids
  end

  test "linked_space_ids returns component IDs for composite space" do
    front_room = spaces(:front_room)
    back_room = spaces(:back_room)
    whole_building = spaces(:whole_building)

    assert_includes whole_building.linked_space_ids, front_room.id
    assert_includes whole_building.linked_space_ids, back_room.id
    assert_equal 2, whole_building.linked_space_ids.size
  end

  test "linked_space_ids returns empty array for unlinked space" do
    standalone = Space.create!(name: "Standalone Room", active: true)

    assert_equal [], standalone.linked_space_ids
  end
end
