class OAuthController < ApplicationController
  before_action :authenticate_user!
  
  SPOTIFY_AUTH_URL = 'https://accounts.spotify.com/authorize'.freeze
  SPOTIFY_TOKEN_URL = 'https://accounts.spotify.com/api/token'.freeze
  
  # Start OAuth flow by redirecting to Spotify
  def authorize
    provider = params[:provider]
    
    case provider
    when 'spotify'
      redirect_to spotify_auth_url, allow_other_host: true
    else
      render json: { error: 'Unsupported provider' }, status: :unprocessable_entity
    end
  end

  # Handle callback from Spotify
  def callback
    provider = params[:provider] || 'spotify' # Default to Spotify for now
    
    if params[:error]
      # Handle error from OAuth provider
      render json: { error: params[:error] }, status: :unprocessable_entity
      return
    end
    
    # Use authorization code to get access token
    case provider
    when 'spotify'
      handle_spotify_callback
    else
      render json: { error: 'Unsupported provider' }, status: :unprocessable_entity
    end
  end
  
  private
  
  def spotify_auth_url
    query_params = {
      client_id: ENV['SPOTIFY_CLIENT_ID'],
      response_type: 'code',
      redirect_uri: spotify_callback_url,
      scope: 'user-read-private user-read-email user-library-read playlist-read-private',
      state: generate_state_param
    }
    
    "#{SPOTIFY_AUTH_URL}?#{query_params.to_query}"
  end
  
  def handle_spotify_callback
    code = params[:code]
    
    # Exchange authorization code for access token
    response = HTTParty.post(SPOTIFY_TOKEN_URL, {
      body: {
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: spotify_callback_url,
        client_id: ENV['SPOTIFY_CLIENT_ID'],
        client_secret: ENV['SPOTIFY_CLIENT_SECRET']
      }
    })
    
    if response.success?
      token_data = JSON.parse(response.body)
      
      # Find or create linked account
      linked_account = current_user.linked_accounts.find_or_initialize_by(provider: LinkedAccount::SPOTIFY)
      linked_account.access_token = token_data['access_token']
      linked_account.refresh_token = token_data['refresh_token']
      linked_account.expires_at = Time.current + token_data['expires_in'].to_i.seconds
      
      if linked_account.save
        render json: { success: true, message: 'Successfully connected to Spotify' }
      else
        render json: { error: linked_account.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Failed to obtain access token' }, status: :unprocessable_entity
    end
  end
  
  def spotify_callback_url
    oauth_callback_url(provider: 'spotify')
  end
  
  def generate_state_param
    # Generate a random string to protect against CSRF
    state = SecureRandom.hex(16)
    session[:oauth_state] = state
    state
  end
end
