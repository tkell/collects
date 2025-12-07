class AuthenticationController < ApplicationController
  def new
    # Just render the login form
  end

  def login
    user = User.find_by(email: params[:email].downcase)
    if user && user.authenticate(params[:password])
      token = JWT.encode({user_id: user.id}, Rails.application.credentials.read)
      expires_at = Time.now + 300.days
      cookies.encrypted[:jwt] = {
        value: token,
        expires: expires_at,
        httponly: true,
        secure: Rails.env.production?, # Use secure in production
      }
      session[:user_id] = user.id

      render json: {message: "Logged in", username: user.username, expires_at: expires_at}, status: :ok
    else
      render json: {error: 'Invalid credentials'}, status: :unauthorized
    end
  end

  def logout
    # Clear the JWT cookie
    cookies.delete(:jwt)
    # Clear the Rails session
    reset_session
    render json: {message: "Logged out"}, status: :ok
  end
end
