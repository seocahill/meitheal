class Admin::EmailGroupsController < ApplicationController
  before_action :require_owner
  before_action :set_email_group, only: [ :show, :edit, :update, :destroy, :add_member, :remove_member ]

  def index
    @email_groups = EmailGroup.order(:name)
  end

  def show
    @archived_emails = @email_group.archived_emails.recent.limit(50)
  end

  def new
    @email_group = EmailGroup.new
  end

  def create
    @email_group = EmailGroup.new(email_group_params)
    if @email_group.save
      redirect_to admin_email_group_path(@email_group), notice: "Email group created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_members = User.where.not(id: @email_group.member_ids).order(:email_address)
  end

  def update
    if @email_group.update(email_group_params)
      redirect_to admin_email_group_path(@email_group), notice: "Email group updated."
    else
      @available_members = User.where.not(id: @email_group.member_ids).order(:email_address)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @email_group.destroy
    redirect_to admin_email_groups_path, notice: "Email group deleted."
  end

  def add_member
    user = User.find(params[:user_id])
    @email_group.members << user unless @email_group.members.include?(user)
    redirect_to edit_admin_email_group_path(@email_group), notice: "#{user.email_address} added to group."
  end

  def remove_member
    user = User.find(params[:user_id])
    @email_group.members.delete(user)
    redirect_to edit_admin_email_group_path(@email_group), notice: "#{user.email_address} removed from group."
  end

  private

  def set_email_group
    @email_group = EmailGroup.find(params[:id])
  end

  def email_group_params
    params.require(:email_group).permit(:name, :local_part, :description, :active)
  end
end
