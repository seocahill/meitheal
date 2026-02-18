class Admin::FaqsController < ApplicationController
  before_action :require_authentication
  before_action :require_admin
  before_action :set_faq, only: [ :edit, :update, :destroy, :move_up, :move_down ]

  def index
    @faqs = Faq.by_order
  end

  def new
    @faq = Faq.new(order: Faq.next_order, active: true)
  end

  def create
    @faq = Faq.new(faq_params)
    if @faq.save
      redirect_to admin_faqs_path, notice: "FAQ created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @faq.update(faq_params)
      redirect_to admin_faqs_path, notice: "FAQ updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @faq.destroy
    redirect_to admin_faqs_path, notice: "FAQ deleted."
  end

  def move_up
    swap_with_previous
    redirect_to admin_faqs_path
  end

  def move_down
    swap_with_next
    redirect_to admin_faqs_path
  end

  private

  def set_faq
    @faq = Faq.find(params[:id])
  end

  def faq_params
    params.require(:faq).permit(:question, :answer, :order, :active)
  end

  def require_admin
    unless Current.user&.can_manage?
      redirect_to root_path, alert: "You don't have permission to do that."
    end
  end

  def swap_with_previous
    previous_faq = Faq.where("\"order\" < ? OR (\"order\" IS NULL AND ? IS NOT NULL) OR (\"order\" IS NULL AND id < ?)",
                             @faq.order || Float::INFINITY, @faq.order, @faq.id)
                     .by_order.last
    return unless previous_faq

    @faq.order, previous_faq.order = previous_faq.order, @faq.order
    @faq.save!
    previous_faq.save!
  end

  def swap_with_next
    next_faq = Faq.where("\"order\" > ? OR (\"order\" IS NOT NULL AND ? IS NULL) OR (\"order\" IS NULL AND id > ?)",
                        @faq.order || -Float::INFINITY, @faq.order, @faq.id)
                  .by_order.first
    return unless next_faq

    @faq.order, next_faq.order = next_faq.order, @faq.order
    @faq.save!
    next_faq.save!
  end
end
