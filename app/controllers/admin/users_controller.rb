module Admin
  class UsersController < BaseController
    include Pagy::Method

    before_action :require_owner
    before_action :set_user, only: [ :edit, :update, :destroy, :approve ]

    def index
      users_scope = User.order(:email_address)
      users_scope = users_scope.where(approved: false) if params[:approved] == "pending"
      @pagy, @users = pagy(users_scope, limit: 25)
      @pending_count = User.where(approved: false).count
    end

    def approve
      @user.update!(approved: true)
      @user.memberships.create!(membership_type: :associate, starts_on: Date.current) unless @user.memberships.exists?
      UserMailer.account_approved(@user).deliver_later
      redirect_to admin_users_path, notice: "#{@user.profile&.name || @user.email_address} has been approved and notified."
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      @user.approved = true # Admin-created users are automatically approved
      if @user.save
        redirect_to admin_users_path, notice: "User created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @user.update(user_params.except(:password).merge(password_params))
        redirect_to admin_users_path, notice: "User updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == Current.user
        redirect_to admin_users_path, alert: "You cannot delete yourself."
      else
        @user.destroy
        redirect_to admin_users_path, notice: "User deleted."
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email_address, :password, :role, :approved)
    end

    def password_params
      params[:user][:password].present? ? { password: params[:user][:password] } : {}
    end
  end
end
