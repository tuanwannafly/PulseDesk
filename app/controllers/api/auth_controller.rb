module Api
  class AuthController < ApplicationController
    skip_before_action :verify_authenticity_token, raise: false
    skip_before_action :require_login, only: %i[login csrf]

    # POST /api/auth/login
    # Body: { subdomain:, email:, password: }
    def login
      subdomain = params[:subdomain].to_s.strip.downcase
      email     = params[:email].to_s.strip.downcase
      password  = params[:password].to_s

      account = Account.find_by(subdomain: subdomain)
      unless account
        return render json: { error: 'Unknown subdomain' }, status: :unauthorized
      end

      user = account.users.find_by(email: email)
      unless user&.authenticate(password)
        return render json: { error: 'Invalid email or password' }, status: :unauthorized
      end

      # Reuse existing HTML session flow
      reset_session
      session[:user_id] = user.id
      Current.account = user.account

      render json: { user: user_payload(user) }
    end

    # DELETE /api/auth/login
    def logout
      reset_session
      Current.account = nil
      render json: { ok: true }
    end

    # GET /api/auth/me
    def me
      unless current_user
        return render json: { error: 'Not authenticated' }, status: :unauthorized
      end
      render json: { user: user_payload(current_user) }
    end

    private

    def current_user
      @current_user ||= User.find_by(id: session[:user_id])
    end

    def user_payload(user)
      {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        account: {
          id: user.account.id,
          company_name: user.account.company_name,
          subdomain: user.account.subdomain,
          plan: user.account.plan
        }
      }
    end
  end
end
