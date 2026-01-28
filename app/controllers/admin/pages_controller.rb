class Admin::PagesController < ApplicationController
  before_action :require_editor
  before_action :set_page, only: [ :show, :edit, :update, :destroy, :publish, :unpublish ]

  def index
    @pages = Page.order(updated_at: :desc)
  end

  def show
    redirect_to page_path(@page.slug)
  end

  def new
    @page = Page.new
  end

  def create
    @page = Page.new(page_params)
    if @page.save
      redirect_to page_path(@page.slug), notice: "Page created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @page.update(page_params)
      redirect_to page_path(@page.slug), notice: "Page updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @page.destroy
    redirect_to admin_pages_path, notice: "Page deleted."
  end

  def publish
    @page.update!(published: true)
    redirect_to page_path(@page.slug), notice: "Page published."
  end

  def unpublish
    @page.update!(published: false)
    redirect_to admin_pages_path, notice: "Page unpublished."
  end

  private

  def set_page
    @page = Page.find(params[:id])
  end

  def page_params
    params.require(:page).permit(:title, :slug, :content, :published)
  end
end
