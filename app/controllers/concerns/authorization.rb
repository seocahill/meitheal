module Authorization
  extend ActiveSupport::Concern

  included do
    helper_method :current_user_can_edit?, :current_user_can_manage?
  end

  private

  def require_editor
    unless current_user_can_edit?
      redirect_to root_path, alert: "You don't have permission to do that."
    end
  end

  def require_owner
    unless current_user_can_manage?
      redirect_to root_path, alert: "You don't have permission to do that."
    end
  end

  def current_user_can_edit?
    Current.user&.can_edit?
  end

  def current_user_can_manage?
    Current.user&.can_manage?
  end
end
