class UserSettingsController < ApplicationController
  def update
    authenticate_user
    @user_settings = UserSettings.find(params[:id])

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
