class AuthenticationController < ApplicationController
  def login
    user = User.find_by(email: params[:email].downcase)
    if user && user.authenticate(params[:password])
      token = JWT.encode({user_id: user.id}, Rails.application.secrets.secret_key_base)
      cookies.encrypted[:jwt] = {
        value: token,
        httponly: true,
        secure: Rails.env.production?, # Use secure in production
        expires: 1.day.from_now
      }

      render json: { message: "Logged in successfully" }, status: :ok
    else
      render json: {error: 'Invalid credentials'}, status: :unauthorized
    end
  end
end
