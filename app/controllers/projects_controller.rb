class ProjectsController < ApplicationController
  include Pagy::Method

  allow_unauthenticated_access only: [ :index, :show ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy, :publish, :unpublish ]
  before_action :require_editable, only: [ :edit, :update, :destroy ]
  before_action :require_publishable, only: [ :publish, :unpublish ]

  def index
    @pagy, @posts = pagy(Post.project.published.recent, items: 10)
  end

  def show
    unless @post.published? || can_view_draft?(@post)
      redirect_to projects_path, alert: "Project not found."
    end
  end

  def new
    @post = Post.new(post_type: :project)
  end

  def create
    @post = Current.user.posts.build(post_params.merge(post_type: :project))
    if @post.save
      redirect_to project_path(@post.slug), notice: "Project created. It will be visible after an admin publishes it."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    filtered_params = post_params
    unless Current.user.can_edit?
      filtered_params = filtered_params.except(:published_at)
    end

    if @post.update(filtered_params)
      redirect_to project_path(@post.slug), notice: "Project updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to projects_path, notice: "Project deleted."
  end

  def publish
    @post.update!(published_at: Time.current)
    redirect_to project_path(@post.slug), notice: "Project published."
  end

  def unpublish
    @post.update!(published_at: nil)
    redirect_to project_path(@post.slug), notice: "Project unpublished."
  end

  private

  def set_post
    @post = Post.project.find_by!(slug: params[:slug])
  end

  def post_params
    params.require(:post).permit(
      :title, :slug, :excerpt, :body, :published_at, :featured_image
    )
  end

  def can_view_draft?(post)
    authenticated? && (post.user == Current.user || Current.user.can_edit?)
  end

  def require_editable
    unless @post.editable_by?(Current.user)
      redirect_to root_path, alert: "You don't have permission to do that."
    end
  end

  def require_publishable
    unless @post.publishable_by?(Current.user)
      redirect_to root_path, alert: "You don't have permission to do that."
    end
  end
end
