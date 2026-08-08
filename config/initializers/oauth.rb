Rails.application.config.spotify = {
  client_id: ENV['SPOTIFY_CLIENT_ID'],
  client_secret: ENV['SPOTIFY_CLIENT_SECRET']
}

Rails.application.config.discogs = {
  consumer_key: ENV['DISCOGS_CONSUMER_KEY'],
  consumer_secret: ENV['DISCOGS_CONSUMER_SECRET'],
  user_agent: "tessellates-user-agent",
  callback_url: "https://tessellates.space/oauth_callback/discogs"
}

module OAuthConfig
  def self.get_provider_config(provider)
    case provider.to_s.downcase
    when 'spotify'
      Rails.application.config.spotify
    when 'discogs'
      Rails.application.config.discogs
    else
      raise "Unknown OAuth provider: #{provider}"
    end
  end
end
