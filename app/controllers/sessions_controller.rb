class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
    redirect_to root_path if logged_in?
  end

  def create
    subdomain = params[:subdomain].to_s.downcase.strip
    account   = Account.find_by(subdomain: subdomain)

    if account.nil?
      flash.now[:alert] = 'Unknown workspace.'
      return render :new, status: :unprocessable_entity
    end

    user = account.users.find_by(email: params[:email].to_s.downcase.strip)

    if user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: "Welcome back, #{user.name}!"
    else
      flash.now[:alert] = 'Invalid email or password.'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: 'Logged out.'
  end
end
