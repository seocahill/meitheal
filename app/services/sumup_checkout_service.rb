class SumupCheckoutService
  CHECKOUT_URL = "https://api.sumup.com/v0.1/checkouts".freeze
  TRANSACTIONS_URL = "https://api.sumup.com/v0.1/me/transactions/history".freeze

  class CheckoutError < StandardError; end

  def initialize
    @api_key = Rails.application.credentials.dig(:sumup_api_key) || ENV["SUMUP_API_KEY"]
    @merchant_code = Rails.application.credentials.dig(:sumup_merchant_code) || ENV["SUMUP_MERCHANT_CODE"]
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

  # Returns { "items" => [...], "links" => [...] }
  # Supported filters: oldest_time, newest_time, statuses, payment_types, limit, order
  def list_transactions(filters = {})
    uri = URI(TRANSACTIONS_URL)
    uri.query = URI.encode_www_form(filters.compact) if filters.any?

    request = Net::HTTP::Get.new(uri, headers)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    JSON.parse(response.body)
  end

  private

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
