class UsersController < ApplicationController
  skip_before_action :authenticate_user, only: [:new, :create], if: -> { method_defined?(:authenticate_user) }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    if @user.save
      respond_to do |format|
        format.json { render json: { message: "User created successfully" }, status: :created }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :username, :password, :password_confirmation)
  end
end
