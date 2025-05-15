class LinkedAccount < ApplicationRecord
  belongs_to :user
  belongs_to :collection
  
  # Provider types
  SPOTIFY = 'spotify'.freeze
  
  validates :provider, presence: true
  validates :access_token, presence: true
  
  # Check if the token is expired
  def expired?
    expires_at.present? && expires_at < Time.current
  end
  
  # Refresh token methods can be implemented based on provider
  def refresh_spotify_token
    # This would be implemented with the Spotify API
    # We'd make a request to Spotify to refresh the token
    # and update the access_token and expires_at
  end
end
