class Admin::InboxController < Admin::BaseController
  include Pagy::Method

  before_action :require_owner
  before_action :set_email, only: [ :show, :archive, :unarchive, :create_todo, :create_newsletter, :create_funding ]

  ALLOWED_LIMITS = [ 5, 10, 25, 50 ].freeze
  DEFAULT_LIMIT = 10

  def index
    @show_archived = params[:show_archived] == "true"
    limit = params[:limit].to_i
    limit = DEFAULT_LIMIT unless ALLOWED_LIMITS.include?(limit)

    scope = @show_archived ? CachedEmail.archived : CachedEmail.visible
    @pagy, @emails = pagy(scope.order(received_at: :desc), limit: limit)
  end

  def show
    @email.read! if @email.unread?
  end

  def archive
    @email.archived!
    redirect_to admin_inbox_index_path, notice: "Email archived."
  end

  def unarchive
    @email.read!
    redirect_to admin_inbox_index_path(show_archived: true), notice: "Email unarchived."
  end

  def batch_archive
    ids = params[:ids] || []
    CachedEmail.where(id: ids).update_all(status: :archived)
    redirect_to admin_inbox_index_path, notice: "#{ids.size} emails archived."
  end

  def create_todo
    AdminTodo.create!(@email.to_admin_todo_attrs)
    redirect_to admin_inbox_path(@email), notice: "Todo created."
  rescue => e
    redirect_to admin_inbox_path(@email), alert: "Could not create todo: #{e.message}"
  end

  def create_newsletter
    newsletter = Newsletter.create!(
      subject: @email.subject,
      content: @email.body
    )
    redirect_to edit_newsletter_path(newsletter), notice: "Newsletter draft created from email."
  rescue => e
    redirect_to admin_inbox_path(@email), alert: "Could not create newsletter: #{e.message}"
  end

  def create_funding
    funding = FundingOpportunity.create!(
      title: @email.subject,
      description: @email.body,
      organization: "TBD - from email",
      deadline: 30.days.from_now.to_date
    )
    redirect_to edit_funding_opportunity_path(funding), notice: "Funding opportunity draft created. Please update the details."
  rescue => e
    redirect_to admin_inbox_path(@email), alert: "Could not create funding opportunity: #{e.message}"
  end

  private

  def set_email
    @email = CachedEmail.find(params[:id])
  end
end
