class ZohoMailService
  class ApiError < StandardError; end
  class AuthenticationError < ApiError; end

  # Zoho data centers - EU for Ireland
  REGIONS = {
    us: "https://mail.zoho.com",
    eu: "https://mail.zoho.eu",
    in: "https://mail.zoho.in",
    au: "https://mail.zoho.com.au",
    jp: "https://mail.zoho.jp"
  }.freeze

  OAUTH_REGIONS = {
    us: "https://accounts.zoho.com",
    eu: "https://accounts.zoho.eu",
    in: "https://accounts.zoho.in",
    au: "https://accounts.zoho.com.au",
    jp: "https://accounts.zoho.jp"
  }.freeze

  def initialize
    @region = (Rails.application.credentials.dig(:zoho_region) || ENV["ZOHO_REGION"] || "eu").to_sym
    @client_id = Rails.application.credentials.dig(:zoho_client_id) || ENV["ZOHO_CLIENT_ID"]
    @client_secret = Rails.application.credentials.dig(:zoho_client_secret) || ENV["ZOHO_CLIENT_SECRET"]
    @refresh_token = Rails.application.credentials.dig(:zoho_refresh_token) || ENV["ZOHO_REFRESH_TOKEN"]
    @account_id = Rails.application.credentials.dig(:zoho_account_id) || ENV["ZOHO_ACCOUNT_ID"]
  end

  def configured?
    @client_id.present? && @client_secret.present? && @refresh_token.present? && @account_id.present?
  end

  def folders
    response = get("/api/accounts/#{@account_id}/folders")
    response["data"] || []
  end

  def emails(folder_id:, limit: 25, start: 0)
    params = {
      folderId: folder_id,
      limit: limit,
      start: start,
      sortBy: "date",
      sortorder: "false" # descending
    }

    response = get("/api/accounts/#{@account_id}/messages/view", params)
    response["data"] || []
  end

  def search_emails(query:, limit: 25, received_time: nil)
    params = {
      searchKey: query,
      limit: limit
    }
    params[:receivedTime] = received_time if received_time

    response = get("/api/accounts/#{@account_id}/messages/search", params)
    response["data"] || []
  end

  def email(folder_id:, message_id:)
    response = get("/api/accounts/#{@account_id}/folders/#{folder_id}/messages/#{message_id}/content")
    response["data"]
  end

  def email_metadata(folder_id:, message_id:)
    response = get("/api/accounts/#{@account_id}/folders/#{folder_id}/messages/#{message_id}/details")
    response["data"]
  end

  def attachments(folder_id:, message_id:)
    response = get("/api/accounts/#{@account_id}/folders/#{folder_id}/messages/#{message_id}/attachmentinfo")
    response["data"]&.dig("attachments") || []
  rescue ApiError
    # Return empty array if no attachments or error
    []
  end

  # Download an inline image embedded in an email body.
  # The content_id corresponds to the `cid` parameter in Zoho's /mail/ImageDisplay URLs.
  def download_inline_image(folder_id:, message_id:, content_id:)
    response = raw_connection.get("/api/accounts/#{@account_id}/folders/#{folder_id}/messages/#{message_id}/inline") do |req|
      req.params = { contentId: content_id }
    end

    raise ApiError, "Could not download inline image (#{response.status})" unless response.status == 200

    response.body
  end

  def download_attachment(folder_id:, message_id:, attachment_id:)
    # First get attachment info for filename and content type
    attachments_list = attachments(folder_id: folder_id, message_id: message_id)
    attachment_info = attachments_list.find { |a| a["attachmentId"] == attachment_id }

    # Download the attachment binary
    response = raw_connection.get("/api/accounts/#{@account_id}/folders/#{folder_id}/messages/#{message_id}/attachments/#{attachment_id}")

    if response.status != 200
      raise ApiError, "Could not download attachment"
    end

    {
      content: response.body,
      filename: attachment_info&.dig("attachmentName") || "attachment",
      content_type: attachment_info&.dig("contentType") || "application/octet-stream"
    }
  end

  private

  def base_url
    REGIONS[@region] || REGIONS[:eu]
  end

  def oauth_url
    OAUTH_REGIONS[@region] || OAUTH_REGIONS[:eu]
  end

  def access_token
    @access_token ||= cached_access_token
  end

  def cached_access_token
    cache_key = "zoho_access_token_#{@account_id}"
    Rails.cache.fetch(cache_key, expires_in: 55.minutes) do
      fetch_access_token
    end
  end

  def fetch_access_token
    response = Faraday.post("#{oauth_url}/oauth/v2/token") do |req|
      req.params = {
        refresh_token: @refresh_token,
        client_id: @client_id,
        client_secret: @client_secret,
        grant_type: "refresh_token"
      }
    end

    body = JSON.parse(response.body)

    if body["error"]
      Rails.logger.error("Zoho OAuth error: #{body['error']}")
      raise AuthenticationError, body["error"]
    end

    body["access_token"]
  end

  def clear_cached_token
    Rails.cache.delete("zoho_access_token_#{@account_id}")
    @access_token = nil
    @connection = nil
  end

  def get(path, params = {})
    response = connection.get(path) do |req|
      req.params = params
    end

    handle_response(response)
  end

  def connection
    @connection ||= Faraday.new(url: base_url) do |f|
      f.request :json
      f.response :json
      f.headers["Authorization"] = "Zoho-oauthtoken #{access_token}"
      f.headers["Accept"] = "application/json"
    end
  end

  def raw_connection
    @raw_connection ||= Faraday.new(url: base_url) do |f|
      f.headers["Authorization"] = "Zoho-oauthtoken #{access_token}"
    end
  end

  def handle_response(response)
    case response.status
    when 200
      response.body
    when 401
      clear_cached_token
      raise AuthenticationError, "Invalid or expired token"
    when 429
      raise ApiError, "Rate limit exceeded"
    else
      error_message = response.body.is_a?(Hash) ? response.body["status"]&.dig("description") : response.body
      raise ApiError, "Zoho API error (#{response.status}): #{error_message}"
    end
  end
end
