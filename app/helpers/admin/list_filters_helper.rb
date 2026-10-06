# Keeps the filters of an admin list when moving between its tabs, presets and pages.
module Admin::ListFiltersHelper
  NAVIGATION_PARAMS = %w[page commit utf8].freeze

  # The current list's filters, without the page.
  def list_filters
    request.query_parameters.except(*NAVIGATION_PARAMS)
  end

  # Link to the current list with some filters changed. A nil value clears that filter.
  def list_path(overrides = {})
    query = list_filters.merge(overrides.stringify_keys).compact_blank.to_query
    query.empty? ? request.path : "#{request.path}?#{query}"
  end

  # Hidden fields so a form carries the filters it has no input for.
  def hidden_filter_fields(*keys)
    safe_join(keys.filter_map { |key|
      hidden_field_tag(key, list_filters[key.to_s], id: nil) if list_filters[key.to_s].present?
    })
  end
end
