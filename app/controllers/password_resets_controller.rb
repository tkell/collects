class PasswordResetsController < ApplicationController

  def create
    user = User.find_by(email: params[:email]&.downcase)
    if user && user.email_verified?
      user.generate_password_reset_token!
      UserMailer.password_reset_email(user).deliver_later
    end
    # return success to prevent email enumeration
    render json: { message: "If that email exists, a reset link has been sent." }, status: :ok
  end

  def update
    user = User.find_by(password_reset_token: params[:token])
    if user.nil? || user.password_reset_expired?
      render json: { error: "Invalid or expired reset token" }, status: :unprocessable_entity
      return
    end

    if user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      user.clear_password_reset_token!
      render json: { message: "Password updated successfully" }, status: :ok
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
