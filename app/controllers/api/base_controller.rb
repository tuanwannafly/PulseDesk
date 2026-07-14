# Base controller for the JSON API consumed by the React SPA.
#
# Key differences from ApplicationController:
#   - Skips CSRF verification (the SPA authenticates via session cookie + same-origin proxy;
#     in production, we issue a CSRF token via /api/auth/csrf and require X-CSRF-Token)
#   - Renders JSON errors with `{ error: "..." }` on failures
#   - Calls set_current_attributes the same way, so TenantScoped still works
class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  before_action :require_login
  before_action :set_current_attributes

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: 'Not found' }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { error: e.message, details: e.record.errors.as_json }, status: :unprocessable_entity
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :unprocessable_entity
  end

  protected

  # Same as the HTML controller's set_current_attributes, but available via the
  # same name so any code that references ApplicationController#current_user
  # still works.
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?
    render json: { error: 'Authentication required' }, status: :unauthorized
  end
end
