class ApplicationController < ActionController::API
  include ActionController::Cookies
  def authenticate_user
    jwt = cookies.encrypted[:jwt]
    begin
      decoded_token = JWT.decode(jwt, Rails.application.credentials.read, true)
      @current_user_id = decoded_token[0]['user_id']
    rescue JWT::DecodeError
      render json: { error: 'Unauthorized - Bad Token' }, status: :unauthorized
    end
  end

  before_action :authenticate_user
end
