class Admin::CalendarImportsController < ApplicationController
  before_action :require_owner

  def new
    @spaces = Space.active.order(:name)
  end

  def create
    unless params[:ical_file].present?
      @spaces = Space.active.order(:name)
      return render :new, status: :unprocessable_entity, alert: "Please select a file."
    end

    space = Space.find(params[:space_id])
    ical_data = params[:ical_file].read

    @result = IcalImportService.new(ical_data, space: space, user: Current.user).import
    @space = space
  rescue ActiveRecord::RecordNotFound
    @spaces = Space.active.order(:name)
    redirect_to new_admin_calendar_import_path, alert: "Please select a valid space."
  end
end
