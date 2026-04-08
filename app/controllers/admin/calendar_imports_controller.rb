class Admin::CalendarImportsController < Admin::BaseController
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
    result = IcalImportService.new(ical_data, space: space, user: Current.user).import

    redirect_to calendar_path, notice: import_notice(result)
  rescue ActiveRecord::RecordNotFound
    @spaces = Space.active.order(:name)
    redirect_to new_admin_calendar_import_path, alert: "Please select a valid space."
  end

  private

  def import_notice(result)
    created = result.created.to_i
    skipped = result.skipped.size
    errors = result.errors.size

    parts = []
    parts << "Imported #{created} booking#{'s' unless created == 1}" if created.positive?
    parts << "skipped #{skipped} duplicate#{'s' unless skipped == 1}" if skipped.positive?
    parts << "no new bookings imported" if parts.empty?
    parts << "#{errors} error#{'s' unless errors == 1}" if errors.positive?

    parts.join(", ").capitalize + "."
  end
end
