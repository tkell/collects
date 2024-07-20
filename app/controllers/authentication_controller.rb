class AuthenticationController < ApplicationController
  def login
    user = User.find_by(email: params[:email].downcase)
    if user && user.authenticate(params[:password])
      token = JWT.encode({user_id: user.id}, Rails.application.secrets.secret_key_base)
      expires_at = Time.now + 30.days
      cookies.encrypted[:jwt] = {
        value: token,
        expires: expires_at,
        httponly: true,
        secure: Rails.env.production?, # Use secure in production
      }

      render json: {message: "Logged in", username: user.username, expires_at: expires_at}, status: :ok
    else
      render json: {error: 'Invalid credentials'}, status: :unauthorized
    end
  end
end
