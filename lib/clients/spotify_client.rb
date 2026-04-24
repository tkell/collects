class SpotifyClient
  require 'httparty'

  BASE_URL = 'https://api.spotify.com/v1'.freeze
  TOKEN_URL = 'https://accounts.spotify.com/api/token'.freeze
  ALBUM_BATCH_SIZE = 20
  TRACK_BATCH_SIZE = 50

  def initialize(access_token)
    @access_token = access_token
  end

  def self.with_client_credentials
    config = OAuthConfig.get_provider_config('spotify')
    response = HTTParty.post(TOKEN_URL, {
      body: {
        grant_type: 'client_credentials',
        client_id: config[:client_id],
        client_secret: config[:client_secret]
      },
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    })

    if response.success?
      new(JSON.parse(response.body)['access_token'])
    else
      raise "Failed to get Spotify client credentials token: #{response.body}"
    end
  end

  def refresh_token(refresh_token)
    config = OAuthConfig.get_provider_config('spotify')
    response = HTTParty.post(TOKEN_URL, {
      body: {
        grant_type: 'refresh_token',
        refresh_token: refresh_token,
        client_id: config[:client_id],
        client_secret: config[:client_secret]
      },
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    })

    if response.success?
      JSON.parse(response.body)
    else
      raise "Failed to refresh Spotify token: #{response.body}"
    end
  end

  def fetch_albums(album_ids)
    albums = []
    album_ids.each_slice(ALBUM_BATCH_SIZE) do |id_batch|
      ids_param = id_batch.join(',')

      response = HTTParty.get("#{BASE_URL}/albums", {
        query: { ids: ids_param },
        headers: { 'Authorization' => "Bearer #{@access_token}" }
      })

      if response.success?
        data = JSON.parse(response.body)
        albums.concat(data['albums'].compact)
      else
        puts "Warning: Failed to fetch album details for batch: #{response.body}"
      end
    end

    albums
  end

  def fetch_tracks(track_ids)
    tracks = []
    track_ids.each_slice(TRACK_BATCH_SIZE) do |id_batch|
      ids_param = id_batch.join(',')

      response = HTTParty.get("#{BASE_URL}/tracks", {
        query: { ids: ids_param },
        headers: { 'Authorization' => "Bearer #{@access_token}" }
      })

      if response.success?
        data = JSON.parse(response.body)
        tracks.concat(data['tracks'].compact)
      else
        puts "Warning: Failed to fetch track details for batch: #{response.body}"
      end
    end

    tracks
  end
end
