class Admin::InboxController < ApplicationController
  before_action :require_owner
  before_action :set_zoho_service

  PER_PAGE = 25

  def index
    unless @zoho.configured?
      @config_error = "Zoho Mail API not configured. Please set ZOHO_CLIENT_ID, ZOHO_CLIENT_SECRET, ZOHO_REFRESH_TOKEN, and ZOHO_ACCOUNT_ID."
      return
    end

    begin
      @folders = @zoho.folders
      @current_folder = params[:folder_id] || inbox_folder_id
      @page = (params[:page] || 1).to_i
      @page = 1 if @page < 1

      @emails = @zoho.emails(folder_id: @current_folder, limit: PER_PAGE, start: (@page - 1) * PER_PAGE)
      @has_more = @emails.size == PER_PAGE
    rescue ZohoMailService::AuthenticationError => e
      @auth_error = "Authentication failed: #{e.message}. Please check your Zoho credentials."
    rescue ZohoMailService::ApiError => e
      @api_error = "API error: #{e.message}"
    end
  end

  def show
    unless @zoho.configured?
      redirect_to admin_inbox_index_path, alert: "Zoho Mail API not configured."
      return
    end

    begin
      folder_id = params[:folder_id] || inbox_folder_id
      @email_content = @zoho.email(folder_id: folder_id, message_id: params[:id])
      @email_metadata = @zoho.email_metadata(folder_id: folder_id, message_id: params[:id])
    rescue ZohoMailService::ApiError => e
      redirect_to admin_inbox_index_path, alert: "Could not load email: #{e.message}"
    end
  end

  private

  def set_zoho_service
    @zoho = ZohoMailService.new
  end

  def inbox_folder_id
    return @folders.find { |f| f["folderName"]&.downcase == "inbox" }&.dig("folderId") if @folders.present?
    nil
  end
end
