require "test_helper"

class DateRangeFilterTest < ActiveSupport::TestCase
  TODAY = Date.new(2026, 10, 6)

  def filter(params)
    DateRangeFilter.new(params, today: TODAY)
  end

  test "no params means no range" do
    assert_nil filter({}).range
    assert_not filter({}).active?
  end

  test "from and to give an inclusive range" do
    assert_equal Date.new(2026, 1, 1)..Date.new(2026, 1, 31), filter(from: "2026-01-01", to: "2026-01-31").range
  end

  test "only from gives an open ended range" do
    range = filter(from: "2026-01-01").range
    assert_equal Date.new(2026, 1, 1), range.begin
    assert_nil range.end
  end

  test "only to gives a range with no start" do
    range = filter(to: "2026-01-31").range
    assert_nil range.begin
    assert_equal Date.new(2026, 1, 31), range.end
  end

  test "unparseable dates are ignored" do
    assert_nil filter(from: "not-a-date", to: "").range
    assert_equal Date.new(2026, 1, 31), filter(from: "31/31/2026", to: "2026-01-31").range.end
  end

  test "this month runs from the first to the last day of the month" do
    assert_equal Date.new(2026, 10, 1)..Date.new(2026, 10, 31), filter(period: "this_month").range
  end

  test "last month" do
    assert_equal Date.new(2026, 9, 1)..Date.new(2026, 9, 30), filter(period: "last_month").range
  end

  test "last 30 days includes today" do
    assert_equal Date.new(2026, 9, 7)..TODAY, filter(period: "last_30_days").range
  end

  test "this year and last year are calendar years" do
    assert_equal Date.new(2026, 1, 1)..Date.new(2026, 12, 31), filter(period: "this_year").range
    assert_equal Date.new(2025, 1, 1)..Date.new(2025, 12, 31), filter(period: "last_year").range
  end

  test "a preset wins over from and to" do
    assert_equal Date.new(2026, 9, 1)..Date.new(2026, 9, 30),
                 filter(period: "last_month", from: "2020-01-01", to: "2020-02-01").range
  end

  test "unknown preset falls back to from and to" do
    assert_equal Date.new(2026, 1, 1)..Date.new(2026, 1, 31),
                 filter(period: "bogus", from: "2026-01-01", to: "2026-01-31").range
  end

  test "a range ending before it starts is swapped so the filter still matches" do
    assert_equal Date.new(2026, 1, 1)..Date.new(2026, 1, 31), filter(from: "2026-01-31", to: "2026-01-01").range
  end

  test "active tracks whether a range applies" do
    assert filter(period: "this_year").active?
    assert filter(from: "2026-01-01").active?
  end

  test "preset is exposed only when valid" do
    assert_equal "this_year", filter(period: "this_year").preset
    assert_nil filter(period: "bogus").preset
  end

  test "to_params round-trips what the filter was built from" do
    assert_equal({ period: "this_year" }, filter(period: "this_year", from: "2026-01-01").to_params)
    assert_equal({ from: "2026-01-01", to: "2026-01-31" }, filter(from: "2026-01-01", to: "2026-01-31").to_params)
    assert_equal({}, filter(from: "junk").to_params)
  end
end
