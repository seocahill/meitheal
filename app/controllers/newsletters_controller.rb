class NewslettersController < ApplicationController
  before_action :require_editor
  before_action :set_newsletter, only: [ :show, :edit, :update, :destroy, :compose_with_ai, :import_email, :export_to_brevo ]

  def index
    @newsletters = Newsletter.order(updated_at: :desc)
  end

  def show
  end

  def new
    @newsletter = Newsletter.build_template
  end

  def create
    @newsletter = Newsletter.new(newsletter_params)
    if @newsletter.save
      redirect_to edit_newsletter_path(@newsletter), notice: "Newsletter created. Start composing!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @zoho = ZohoMailService.new
    @inbox_emails = []
    @inbox_folder_id = nil
    if @zoho.configured?
      begin
        folders = @zoho.folders
        inbox_folder = folders&.find { |f| f["folderName"]&.downcase == "inbox" }
        if inbox_folder
          @inbox_folder_id = inbox_folder["folderId"]
          @inbox_emails = @zoho.emails(folder_id: @inbox_folder_id, limit: 15)
        end
      rescue StandardError
        # Silently fail - inbox emails are optional
      end
    end
  end

  def import_email
    message_id = params[:message_id]
    folder_id = params[:folder_id]

    return render json: { error: "Message ID required" }, status: :bad_request if message_id.blank?

    zoho = ZohoMailService.new
    unless zoho.configured?
      return render json: { error: "Zoho not configured" }, status: :unprocessable_entity
    end

    begin
      # Get email content
      email_metadata = zoho.email_metadata(folder_id: folder_id, message_id: message_id)
      email_content = zoho.email(folder_id: folder_id, message_id: message_id)

      # Create or use existing chat for this newsletter
      @newsletter.chat ||= Chat.create!(model_id: RubyLLM.config.default_model)
      @newsletter.save! if @newsletter.chat_id_changed?

      # Process with AI
      response = @newsletter.chat.ask(import_email_prompt(email_metadata, email_content))
      render json: { content: strip_code_fences(response.content) }
    rescue ZohoMailService::ApiError => e
      render json: { error: "Could not fetch email: #{e.message}" }, status: :unprocessable_entity
    rescue RubyLLM::Error => e
      render json: { error: "AI service unavailable: #{e.message}" }, status: :service_unavailable
    end
  end

  def update
    if @newsletter.update(newsletter_params)
      redirect_to edit_newsletter_path(@newsletter), notice: "Newsletter saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @newsletter.sent?
      redirect_to newsletters_path, alert: "Cannot delete sent newsletters."
    else
      @newsletter.destroy
      redirect_to newsletters_path, notice: "Newsletter deleted."
    end
  end

  def compose_with_ai
    prompt = params[:prompt]
    return render json: { error: "Prompt required" }, status: :bad_request if prompt.blank?

    # Create or use existing chat for this newsletter
    @newsletter.chat ||= Chat.create!(model_id: RubyLLM.config.default_model)
    @newsletter.save! if @newsletter.chat_id_changed?

    begin
      response = @newsletter.chat.ask(compose_prompt(prompt))
      render json: { content: strip_code_fences(response.content) }
    rescue RubyLLM::Error => e
      render json: { error: "AI service unavailable: #{e.message}" }, status: :service_unavailable
    end
  end

  def export_to_brevo
    brevo = BrevoService.new

    unless brevo.configured?
      redirect_to edit_newsletter_path(@newsletter), alert: "Brevo is not configured. Please add API credentials."
      return
    end

    begin
      if @newsletter.brevo_campaign_id.present?
        # Update existing campaign
        brevo.update_campaign(@newsletter.brevo_campaign_id, @newsletter)
        redirect_to edit_newsletter_path(@newsletter), notice: "Newsletter updated in Brevo."
      else
        # Create new campaign
        campaign_id = brevo.create_campaign(@newsletter)
        @newsletter.update!(brevo_campaign_id: campaign_id)
        redirect_to edit_newsletter_path(@newsletter), notice: "Newsletter exported to Brevo as draft."
      end
    rescue BrevoService::ApiError => e
      redirect_to edit_newsletter_path(@newsletter), alert: "Brevo error: #{e.message}"
    end
  end

  private

  def set_newsletter
    @newsletter = Newsletter.find(params[:id])
  end

  def newsletter_params
    params.require(:newsletter).permit(:subject, :content)
  end

  def compose_prompt(user_prompt)
    <<~PROMPT
      You are helping compose a newsletter for NCF (the North Connacht Co-op), an art collective in Ballina, Co. Mayo, Ireland.

      The newsletter should be:
      - Warm and community-focused
      - Written in clear, accessible English
      - Professional but friendly in tone
      - Formatted with clear sections using headers

      Current newsletter subject: #{@newsletter.subject}
      Current content: #{@newsletter.content.to_plain_text.presence || "(empty)"}

      User request: #{user_prompt}

      Respond with ONLY the newsletter content in markdown format. Use ## for section headers. Do not wrap in code blocks.
    PROMPT
  end

  def import_email_prompt(metadata, content)
    <<~PROMPT
      You are helping compose a newsletter for NCF (the North Connacht Co-op), an art collective in Ballina, Co. Mayo, Ireland.

      Transform this email into a newsletter section that can be appended to the current newsletter.

      Email details:
      - From: #{metadata["fromAddress"]}
      - Subject: #{metadata["subject"]}
      - Content: #{content["content"]&.truncate(3000)}

      Current newsletter subject: #{@newsletter.subject}
      Current newsletter content: #{@newsletter.content.to_plain_text.presence || "(empty)"}

      Requirements:
      - Extract the key information from the email
      - Rewrite it in a warm, community-focused tone
      - Format it as a newsletter section with a clear heading
      - Keep it concise but informative
      - Output HTML format suitable for email (use <h3> for section header, <p> for paragraphs)

      Provide ONLY the HTML section to be added, no explanatory text.
    PROMPT
  end

  def strip_code_fences(text)
    text.gsub(/\A```(?:html|markdown)?\n?/, "").gsub(/\n?```\z/, "")
  end
end
