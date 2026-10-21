module Admin
  class UsersController < BaseController
    include Pagy::Method

    # Editors look after members day to day. Adding and deleting users, and
    # editing anyone who is not a plain member, stays with owners.
    before_action :require_editor, only: [ :index, :approve, :edit, :update ]
    before_action :require_owner, except: [ :index, :approve, :edit, :update ]
    before_action :set_user, only: [ :edit, :update, :destroy, :approve ]
    before_action :require_owner_for_privileged_user, only: [ :edit, :update ]

    def index
      users_scope = User.order(:email_address)
      users_scope = users_scope.search(params[:q]) if params[:q].present?
      users_scope = users_scope.where(approved: false) if params[:approved] == "pending"
      users_scope = users_scope.joins(:profile).merge(Profile.with_interest(params[:interest])) if params[:interest].present?
      @pagy, @users = pagy(users_scope, limit: 25)
      @pending_count = User.where(approved: false).count
      @interest_tags = Profile.interest_tags
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

    # An editor who could edit an owner or editor could reset their password and
    # sign in as them, so those accounts are owner-only.
    def require_owner_for_privileged_user
      return if current_user_can_manage? || @user.viewer?

      redirect_to root_path, alert: "You don't have permission to do that."
    end

    # Only owners set roles. Interests are the one profile field admins set here;
    # members cannot see or edit them.
    def user_params
      permitted = [ :email_address, :password, :approved, profile_attributes: [ :interests ] ]
      permitted << :role if current_user_can_manage?
      params.require(:user).permit(permitted)
    end

    def password_params
      params[:user][:password].present? ? { password: params[:user][:password] } : {}
    end
  end
end
