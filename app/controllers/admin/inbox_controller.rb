class Admin::InboxController < ApplicationController
  before_action :require_owner
  before_action :set_email, only: [ :show, :archive, :unarchive, :create_todo, :create_newsletter, :create_funding ]

  PER_PAGE = 5

  def index
    @show_archived = params[:show_archived] == "true"
    @page = [ (params[:page] || 1).to_i, 1 ].max

    scope = @show_archived ? CachedEmail.archived : CachedEmail.visible
    all_emails = scope.order(received_at: :desc).offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
    @has_more = all_emails.size > PER_PAGE
    @emails = all_emails.first(PER_PAGE)
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
    todo = AdminTodo.create!(
      title: "Follow up: #{@email.subject}",
      description: "From: #{@email.from_address}\nReceived: #{@email.received_at.strftime('%B %d, %Y at %I:%M %p')}",
      priority: :normal
    )
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
