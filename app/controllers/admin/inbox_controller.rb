class Admin::InboxController < ApplicationController
  before_action :require_owner
  before_action :set_zoho_service

  PER_PAGE = 10

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
      @folder_id = params[:folder_id] || inbox_folder_id
      @email_content = @zoho.email(folder_id: @folder_id, message_id: params[:id])
      @email_metadata = @zoho.email_metadata(folder_id: @folder_id, message_id: params[:id])
      @attachments = @zoho.attachments(folder_id: @folder_id, message_id: params[:id])
    rescue ZohoMailService::ApiError => e
      redirect_to admin_inbox_index_path, alert: "Could not load email: #{e.message}"
    end
  end

  def attachment
    unless @zoho.configured?
      redirect_to admin_inbox_index_path, alert: "Zoho Mail API not configured."
      return
    end

    begin
      folder_id = params[:folder_id] || inbox_folder_id
      attachment_data = @zoho.download_attachment(
        folder_id: folder_id,
        message_id: params[:id],
        attachment_id: params[:attachment_id]
      )
      send_data attachment_data[:content],
                filename: attachment_data[:filename],
                type: attachment_data[:content_type],
                disposition: "attachment"
    rescue ZohoMailService::ApiError => e
      redirect_to admin_inbox_path(params[:id], folder_id: folder_id), alert: "Could not download attachment: #{e.message}"
    end
  end

  # Create a todo from an email
  def create_todo
    folder_id = params[:folder_id] || inbox_folder_id
    email_metadata = @zoho.email_metadata(folder_id: folder_id, message_id: params[:id])

    todo = AdminTodo.create!(
      title: "Follow up: #{email_metadata['subject']}",
      description: "From: #{email_metadata['fromAddress']}\nReceived: #{format_zoho_datetime(email_metadata['receivedTime'])}",
      priority: :normal
    )

    redirect_to admin_inbox_path(params[:id], folder_id: folder_id), notice: "Todo created."
  rescue => e
    redirect_to admin_inbox_path(params[:id], folder_id: folder_id), alert: "Could not create todo: #{e.message}"
  end

  # Create a newsletter from an email
  def create_newsletter
    folder_id = params[:folder_id] || inbox_folder_id
    email_metadata = @zoho.email_metadata(folder_id: folder_id, message_id: params[:id])
    email_content = @zoho.email(folder_id: folder_id, message_id: params[:id])

    newsletter = Newsletter.create!(
      subject: email_metadata["subject"],
      content: email_content["content"]
    )

    redirect_to edit_newsletter_path(newsletter), notice: "Newsletter draft created from email."
  rescue => e
    redirect_to admin_inbox_path(params[:id], folder_id: folder_id), alert: "Could not create newsletter: #{e.message}"
  end

  # Create a funding opportunity from an email
  def create_funding
    folder_id = params[:folder_id] || inbox_folder_id
    email_metadata = @zoho.email_metadata(folder_id: folder_id, message_id: params[:id])
    email_content = @zoho.email(folder_id: folder_id, message_id: params[:id])

    # Create with placeholder values - user will fill in details
    funding = FundingOpportunity.create!(
      title: email_metadata["subject"],
      description: email_content["content"],
      organization: "TBD - from email",
      deadline: 30.days.from_now.to_date
    )

    redirect_to edit_funding_opportunity_path(funding), notice: "Funding opportunity draft created. Please update the details."
  rescue => e
    redirect_to admin_inbox_path(params[:id], folder_id: folder_id), alert: "Could not create funding opportunity: #{e.message}"
  end

  private

  def set_zoho_service
    @zoho = ZohoMailService.new
  end

  def inbox_folder_id
    return @folders.find { |f| f["folderName"]&.downcase == "inbox" }&.dig("folderId") if @folders.present?
    # For show actions where @folders isn't set
    @zoho.folders.find { |f| f["folderName"]&.downcase == "inbox" }&.dig("folderId")
  end

  def format_zoho_datetime(timestamp)
    return "" unless timestamp
    Time.at(timestamp.to_i / 1000).strftime("%B %d, %Y at %I:%M %p")
  end
end
