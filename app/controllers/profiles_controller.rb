class ProfilesController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]
  before_action :set_profile, only: [ :show ]

  # GET /profiles - Member directory
  def index
    @profiles = Profile.visible

    if params[:skill].present?
      @profiles = @profiles.with_skill(params[:skill])
    end

    if params[:q].present?
      @profiles = @profiles.search(params[:q])
    end

    @profiles = @profiles.order(:name)
  end

  # GET /profiles/:id
  def show
    unless @profile.visible? || owner_of_profile?(@profile)
      redirect_to profiles_path, alert: "Profile not found."
    end
  end

  # GET /my_profile - Show form to create or edit own profile
  def show_my_profile
    @profile = Current.user.profile || Current.user.build_profile
    @membership = Current.user.memberships.order(created_at: :desc).first
    if @profile.persisted?
      render :edit_my_profile
    else
      render :new_my_profile
    end
  end

  # POST /my_profile - Create own profile
  def create
    @profile = Current.user.build_profile(profile_params)
    if @profile.save
      redirect_to profile_path(@profile), notice: "Profile created successfully."
    else
      render :new_my_profile, status: :unprocessable_entity
    end
  end

  # PATCH /my_profile - Update own profile
  def update
    @profile = Current.user.profile
    if @profile.update(profile_params)
      redirect_to profile_path(@profile), notice: "Profile updated successfully."
    else
      render :edit_my_profile, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = Profile.find(params[:id])
  end

  def profile_params
    params.require(:profile).permit(
      :name, :bio, :skills, :website, :location, :visible,
      :avatar, portfolio_images: []
    )
  end

  def owner_of_profile?(profile)
    authenticated? && profile.user == Current.user
  end
end
