class LinkedAccount < ApplicationRecord
  require_relative '../../lib/clients/spotify_client'

  belongs_to :user

  # Provider types
  SPOTIFY = 'spotify'.freeze

  validates :provider, presence: true
  validates :access_token, presence: true

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def refresh!
    case provider
    when SPOTIFY
      refresh_spotify_token!
    else
      raise "Unsupported provider: #{provider}"
    end
  end

  def refresh_spotify_token!
    raise "Missing refresh token for Spotify account" if refresh_token.blank?

    token_data = SpotifyClient.new(nil).refresh_token(refresh_token)
    update!(
      access_token: token_data['access_token'],
      refresh_token: token_data['refresh_token'].presence || refresh_token,
      expires_at: Time.current + token_data['expires_in'].to_i.seconds
    )
  end
end
