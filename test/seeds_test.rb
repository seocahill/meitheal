require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  # Reproduces the db:prepare failure: seeds.rb creates Payment records without
  # the user_email, user_name, and description fields required by
  # migration 20260320105826_add_user_tracking_to_payments.rb
  test "seeds run without errors" do
    assert_nothing_raised { load Rails.root.join("db/seeds.rb") }
  end
end
