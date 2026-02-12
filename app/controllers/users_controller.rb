class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.email_verification_token = SecureRandom.urlsafe_base64(32)

    if @user.save
      UserMailer.verification_email(@user).deliver_later
      render json: { message: "User created successfully. Please check your email to verify your account." }, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def verify_email
    user = User.find_by(email_verification_token: params[:token])

    if user.nil?
      render json: { error: "Invalid verification token" }, status: :not_found
    elsif user.email_verified?
      render json: { message: "Email already verified" }, status: :ok
    else
      user.verify_email!
      render json: { message: "Email verified successfully" }, status: :ok
    end
  end

  def update
    authenticate_user
    @user = User.find(params[:id])

    if @user.update(user_params)
      render json: { message: "User updated successfully" }, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    authenticate_user
    @user = User.find(params[:id])

    ActiveRecord::Base.transaction do
      @user.playbacks.destroy_all
      @user.annotations.destroy_all

      @user.collections.each do |collection|
        collection.gardens.each do |garden|
          garden.garden_releases.destroy_all
          garden.destroy
        end
        collection.releases.destroy_all
        collection.destroy
      end

      @user.destroy
    end

    render json: { message: "User and all associated data deleted successfully" }, status: :ok
  rescue => e
    render json: { error: "Failed to delete user: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def user_params
    params.require(:user).permit(:email, :username, :password, :password_confirmation)
  end
end
