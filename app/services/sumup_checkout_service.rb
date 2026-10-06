class SumupCheckoutService
  CHECKOUT_URL = "https://api.sumup.com/v0.1/checkouts".freeze
  HISTORY_URL = "https://api.sumup.com/v2.1/merchants/%s/transactions/history".freeze

  class CheckoutError < StandardError; end

  def initialize
    if Rails.env.production?
      @api_key = Rails.application.credentials.dig(:sumup_api_key) || ENV["SUMUP_API_KEY"]
      @merchant_code = Rails.application.credentials.dig(:sumup_merchant_code) || ENV["SUMUP_MERCHANT_CODE"]
    else
      @api_key = ENV["SUMUP_SANDBOX_API_KEY"] || Rails.application.credentials.dig(:sumup_api_key) || ENV["SUMUP_API_KEY"]
      @merchant_code = ENV["SUMUP_SANDBOX_MERCHANT_CODE"] || Rails.application.credentials.dig(:sumup_merchant_code) || ENV["SUMUP_MERCHANT_CODE"]
    end
  end

  def create_checkout(amount_cents:, description:, checkout_reference:, return_url: nil)
    raise CheckoutError, "SumUp API key not configured" if @api_key.blank?
    raise CheckoutError, "SumUp merchant code not configured" if @merchant_code.blank?

    response = Net::HTTP.post(
      URI(CHECKOUT_URL),
      checkout_params(amount_cents, description, checkout_reference, return_url).to_json,
      headers
    )

    body = JSON.parse(response.body)

    if response.is_a?(Net::HTTPSuccess)
      body
    else
      Rails.logger.error("SumUp checkout creation failed: #{body}")
      raise CheckoutError, body["message"] || "Failed to create checkout"
    end
  end

  def get_checkout(checkout_id)
    uri = URI("#{CHECKOUT_URL}/#{checkout_id}")
    request = Net::HTTP::Get.new(uri, headers)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  end

  # Every transaction matching the filters, following SumUp's next-page links.
  # SumUp lists oldest first, ten at a time, unless told otherwise, so callers
  # should pass order and limit. Filters: oldest_time and newest_time (Times),
  # order, limit, statuses and payment_types (arrays). Raises rather than
  # returning part of the history when a page fails or there are too many pages.
  def list_transactions(max_pages: 100, **filters)
    raise CheckoutError, "SumUp API key not configured" if @api_key.blank?
    raise CheckoutError, "SumUp merchant code not configured" if @merchant_code.blank?

    query = history_query(filters)
    items = []

    max_pages.times do
      page = get_history_page(query)
      items.concat(page["items"] || [])
      query = next_page_query(page)
      return items if query.nil?
    end

    raise CheckoutError, "SumUp transaction history has more than #{max_pages} pages"
  end

  def list_payouts(filters = {})
    uri = URI("https://api.sumup.com/v1.0/merchants/#{@merchant_code}/payouts")
    uri.query = URI.encode_www_form(filters.compact) if filters.any?

    request = Net::HTTP::Get.new(uri, headers)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  end

  private

  def history_query(filters)
    pairs = filters.flat_map do |key, value|
      case key
      when :statuses, :payment_types then Array(value).map { |v| [ "#{key}[]", v ] }
      else [ [ key.to_s, value.respond_to?(:utc) ? value.utc.iso8601 : value ] ]
      end
    end
    URI.encode_www_form(pairs)
  end

  # The links give the next page as a query string to send to the same endpoint.
  def next_page_query(page)
    href = Array(page["links"]).find { |link| link["rel"] == "next" }&.dig("href")
    return if href.blank?

    href.start_with?("http") ? URI(href).query : href.delete_prefix("?")
  end

  def get_history_page(query)
    uri = URI(format(HISTORY_URL, @merchant_code))
    uri.query = query.presence

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(Net::HTTP::Get.new(uri, headers))
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise CheckoutError, "SumUp responded #{response.code}: #{error_detail(response.body)}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError
    raise CheckoutError, "SumUp returned a response that is not JSON"
  end

  def error_detail(body)
    parsed = JSON.parse(body.to_s)
    parsed.values_at("detail", "message", "title").compact.first || "no detail given"
  rescue JSON::ParserError
    "no detail given"
  end

  def checkout_params(amount_cents, description, checkout_reference, return_url)
    params = {
      checkout_reference: checkout_reference,
      amount: amount_cents / 100.0,
      currency: "EUR",
      merchant_code: @merchant_code,
      description: description
    }
    params[:return_url] = return_url if return_url.present?
    params
  end

  def headers
    {
      "Authorization" => "Bearer #{@api_key}",
      "Content-Type" => "application/json"
    }
  end
end
