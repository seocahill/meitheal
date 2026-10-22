module Admin
  class InterestGroupsController < BaseController
    before_action :require_editor

    # Largest groups first.
    def index
      @groups = Profile.interest_groups.sort_by { |interest, profiles| [ -profiles.size, interest ] }
    end
  end
end
