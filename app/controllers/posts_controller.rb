class PostsController < ApplicationController
  include Pagy::Method

  allow_unauthenticated_access only: [ :index, :show ]
  before_action :set_post, only: [ :show, :edit, :update, :destroy, :publish, :unpublish ]
  before_action :require_editable, only: [ :edit, :update, :destroy ]
  before_action :require_publishable, only: [ :publish, :unpublish ]

  def index
    @pagy, @posts = pagy(Post.published.recent, items: 10)
  end

  def show
    unless @post.published? || can_view_draft?(@post)
      redirect_to posts_path, alert: "Post not found."
    end
  end

  def new
    @post = Post.new
  end

  def create
    @post = Current.user.posts.build(post_params)
    if @post.save
      redirect_to @post, notice: "Post created. It will be visible after an admin publishes it."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Viewers can't change published status even on their own posts
    filtered_params = post_params
    unless Current.user.can_edit?
      filtered_params = filtered_params.except(:published_at)
    end

    if @post.update(filtered_params)
      redirect_to @post, notice: "Post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "Post deleted."
  end

  def publish
    @post.update!(published_at: Time.current)
    redirect_to @post, notice: "Post published."
  end

  def unpublish
    @post.update!(published_at: nil)
    redirect_to @post, notice: "Post unpublished."
  end

  private

  def set_post
    @post = Post.find_by!(slug: params[:slug])
  end

  def post_params
    params.require(:post).permit(
      :title, :slug, :excerpt, :body, :published_at, :featured_image
    )
  end

  def can_view_draft?(post)
    # Must call authenticated? to ensure session is resumed for unauthenticated routes
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
