class UserSettingsController < ApplicationController
  def update
    authenticate_user
    return if performed?

    @user_settings = current_user.user_settings

    if @user_settings.update(user_settings_params)
      render json: { message: "User settings updated successfully" }, status: :ok
    else
      render json: { errors: @user_settings.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def user_settings_params
    params.require(:user_settings).permit(:dark_mode)
  end
end
