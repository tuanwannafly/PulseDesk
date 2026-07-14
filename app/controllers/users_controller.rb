class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
    @account = Account.find_by(subdomain: params[:subdomain]) || Account.new
    @user = @account.users.new
  end

  def create
    @account = Account.find_by(subdomain: params[:subdomain])

    if @account.nil?
      flash[:alert] = 'Unknown workspace.'
      return redirect_to signup_path
    end

    @user = @account.users.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: 'Account created.'
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end
end
