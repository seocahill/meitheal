# Turns the date filter params of an admin list (a preset such as "this_month",
# or a from and/or to date) into an inclusive date range.
class DateRangeFilter
  PRESETS = {
    "this_month" => "This month",
    "last_month" => "Last month",
    "last_30_days" => "Last 30 days",
    "this_year" => "This year",
    "last_year" => "Last year"
  }.freeze

  def initialize(params, today: Date.current)
    @params = params
    @today = today
  end

  # A Range of dates, open ended when only one bound is given, or nil.
  def range
    @range ||= preset ? preset_range : custom_range
  end

  def active?
    range.present?
  end

  def preset
    @params[:period].presence_in(PRESETS.keys)
  end

  # The params that rebuild this filter, for links that must keep it.
  def to_params
    return { period: preset } if preset

    { from: from, to: to }.compact.transform_values(&:iso8601)
  end

  private

  def preset_range
    case preset
    when "this_month"   then @today.beginning_of_month..@today.end_of_month
    when "last_month"   then (@today - 1.month).beginning_of_month..(@today - 1.month).end_of_month
    when "last_30_days" then (@today - 29.days)..@today
    when "this_year"    then @today.beginning_of_year..@today.end_of_year
    when "last_year"    then (@today - 1.year).beginning_of_year..(@today - 1.year).end_of_year
    end
  end

  def custom_range
    return if from.nil? && to.nil?

    from, to = self.from, self.to
    from, to = to, from if from && to && from > to
    from..to
  end

  def from
    parse(@params[:from])
  end

  def to
    parse(@params[:to])
  end

  def parse(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
end
