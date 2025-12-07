class ApplicationController < ActionController::API
  include ActionController::Cookies
  def authenticate_user
    jwt = cookies.encrypted[:jwt]
    begin
      decoded_token = JWT.decode(jwt, Rails.application.credentials.read, true)
      jwt_user_id = decoded_token.first['user_id']

      if session[:user_id] != jwt_user_id
        logger.info("Login failed, invalid session")
        render json: { error: 'Unauthorized' }, status: :unauthorized
        return
      end

      user = User.find_by(id: jwt_user_id)
      if not user
        logger.info("Login failed, invalid user")
        render json: { error: 'Unauthorized' }, status: :unauthorized
        return
      end

      @current_user_id = jwt_user_id
      @current_user = user

    rescue JWT::ExpiredSignature
      logger.info("Login failed, token expired")
      render json: { error: 'Unauthorized' }, status: :unauthorized
    rescue JWT::DecodeError
      logger.info("Login failed, invalid JSON")
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  # Alias for authenticate_user to match OAuth controller naming
  alias authenticate_user! authenticate_user

  def current_user
    @current_user ||= User.find_by(id: @current_user_id) if @current_user_id
  end
end
