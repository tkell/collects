# OAuth Configuration
# These values should be set in Rails credentials or environment variables

# Spotify OAuth configuration
Rails.application.config.spotify = {
  client_id: ENV['SPOTIFY_CLIENT_ID'],
  client_secret: ENV['SPOTIFY_CLIENT_SECRET'],
  redirect_uri: ENV['SPOTIFY_REDIRECT_URI'],
  scopes: [
    'user-read-private',
    'user-read-email',
    'user-library-read',
    'playlist-read-private'
  ]
}

# Add helper methods to access OAuth configurations
module OAuthConfig
  def self.get_provider_config(provider)
    case provider.to_s.downcase
    when 'spotify'
      Rails.application.config.spotify
    else
      raise "Unknown OAuth provider: #{provider}"
    end
  end
end
