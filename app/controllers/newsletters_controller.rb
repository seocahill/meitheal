class NewslettersController < ApplicationController
  before_action :require_editor
  before_action :set_newsletter, only: [ :show, :edit, :update, :destroy, :compose_with_ai ]

  def index
    @newsletters = Newsletter.order(updated_at: :desc)
  end

  def show
  end

  def new
    @newsletter = Newsletter.new
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
    @archived_emails = ArchivedEmail.recent.includes(:email_group).limit(20)
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
      render json: { content: response.content }
    rescue RubyLLM::Error => e
      render json: { error: "AI service unavailable: #{e.message}" }, status: :service_unavailable
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

      Please provide the newsletter content in HTML format suitable for email. Use <h2> for section headers, <p> for paragraphs, <ul>/<li> for lists.
    PROMPT
  end
end
