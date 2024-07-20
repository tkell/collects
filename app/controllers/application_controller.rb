class ApplicationController < ActionController::API
  include ActionController::Cookies
  def authenticate_user
    jwt = cookies.encrypted[:jwt]
    begin
      decoded_token = JWT.decode(jwt, Rails.application.secrets.secret_key_base, true)
      @current_user_id = decoded_token[0]['user_id']
    rescue JWT::DecodeError
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
