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

  # Alias for authenticate_user to match OAuth controller naming
  alias authenticate_user! authenticate_user

  def current_user
    @current_user ||= User.find_by(id: @current_user_id) if @current_user_id
  end
end
