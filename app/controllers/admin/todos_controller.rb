class Admin::TodosController < ApplicationController
  before_action :require_owner
  before_action :set_todo, only: [ :edit, :update, :destroy, :toggle ]

  def index
    @show_completed = params[:show_completed] == "true"

    @todos = if @show_completed
      AdminTodo.default_order
    else
      AdminTodo.pending.default_order
    end

    @overdue_count = AdminTodo.overdue.count
    @due_soon_count = AdminTodo.due_soon.count
  end

  def new
    @todo = AdminTodo.new
  end

  def create
    @todo = AdminTodo.new(todo_params)
    if @todo.save
      redirect_to admin_todos_path, notice: "Todo added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @todo.update(todo_params)
      respond_to do |format|
        format.html { redirect_to admin_todos_path, notice: "Todo updated." }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @todo.destroy
    redirect_to admin_todos_path, notice: "Todo deleted."
  end

  def toggle
    @todo.toggle_completed!
    respond_to do |format|
      format.html { redirect_to admin_todos_path }
      format.turbo_stream
    end
  end

  # Batch actions
  def batch_complete
    ids = params[:todo_ids] || []
    AdminTodo.where(id: ids).update_all(completed: true)
    redirect_to admin_todos_path, notice: "#{ids.size} todos marked complete."
  end

  def batch_delete
    ids = params[:todo_ids] || []
    AdminTodo.where(id: ids).destroy_all
    redirect_to admin_todos_path, notice: "#{ids.size} todos deleted."
  end

  private

  def set_todo
    @todo = AdminTodo.find(params[:id])
  end

  def todo_params
    params.require(:admin_todo).permit(:title, :description, :due_date, :priority, :completed, :position)
  end
end
