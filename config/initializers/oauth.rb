Rails.application.config.spotify = {
  client_id: ENV['SPOTIFY_CLIENT_ID'],
  client_secret: ENV['SPOTIFY_CLIENT_SECRET']
}

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
