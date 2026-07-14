class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :set_current_attributes
  before_action :require_login

  helper_method :current_user, :logged_in?

  private

  def set_current_attributes
    Current.request_id = request.request_id
    Current.account    = current_user&.account
    Current.user       = current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    flash[:alert] = 'Please log in to continue.'
    redirect_to login_path
  end

  def require_admin
    return if current_user&.admin?

    flash[:alert] = 'Admins only.'
    redirect_to root_path
  end
end
