class SpotifyLikedSongsReleaseSource < ReleaseSource
  require 'httparty'

  BASE_URL = 'https://api.spotify.com/v1'.freeze
  ALBUM_BATCH_SIZE = 20
  PAGE_SIZE = 50

  def import_releases(overwrite_strategy, current_releases)
    spotify_account = get_spotify_linked_account
    raise "No Spotify account linked for this collection's user" unless spotify_account

    if spotify_account.expired?
      refresh_token(spotify_account)
    end

    puts "Starting import from Spotify"
    liked_tracks = fetch_liked_songs(spotify_account.access_token)

    puts "Starting processing from Spotify"
    all_releases = process_spotify_tracks(liked_tracks, spotify_account.access_token)

    puts "Done processing, saving .."
    load_all_releases(all_releases, current_releases, overwrite_strategy)
  end

  private

  def get_spotify_linked_account
    collection.user.linked_accounts.find_by(provider: LinkedAccount::SPOTIFY)
  end

  def refresh_token(spotify_account)
    config = OAuthConfig.get_provider_config('spotify')
    
    response = HTTParty.post('https://accounts.spotify.com/api/token', {
      body: {
        grant_type: 'refresh_token',
        refresh_token: spotify_account.refresh_token,
        client_id: config[:client_id],
        client_secret: config[:client_secret]
      },
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    })

    if response.success?
      token_data = JSON.parse(response.body)
      spotify_account.update!(
        access_token: token_data['access_token'],
        expires_at: Time.current + token_data['expires_in'].to_i.seconds
      )
    else
      raise "Failed to refresh Spotify token: #{response.body}"
    end
  end

  def fetch_liked_songs(access_token)
    tracks = []
    offset = 0

    loop do
      response = HTTParty.get("#{BASE_URL}/me/tracks", {
        query: { limit: PAGE_SIZE, offset: offset },
        headers: { 'Authorization' => "Bearer #{access_token}" }
      })

      unless response.success?
        raise "Failed to fetch liked songs: #{response.body}"
      end

      data = JSON.parse(response.body)
      tracks.concat(data['items'])
      
      break if data['items'].length < PAGE_SIZE || data['next'].nil?
      offset += PAGE_SIZE
    end

    tracks
  end

  def process_spotify_tracks(spotify_tracks, access_token)
    releases_by_album = {}

    spotify_tracks.each do |item|
      track = item['track']
      album = track['album']
      album_id = album['id']
      
      unless releases_by_album[album_id]
        releases_by_album[album_id] = {
          'external_id' => album_id,
          'title' => album['name'],
          'artist' => album['artists'].map { |a| a['name'] }.join(', '),
          'label' => album['label'] || nil,
          'release_year' => extract_year_from_date(album['release_date']),
          'purchase_date' => item['added_at'],
          'image_path' => album['images'].first&.dig('url') || nil,
          'tracks' => []
        }
      else
        existing_purchase_date = releases_by_album[album_id]['purchase_date']
        this_purchase_date = item['added_at']
        if this_purchase_date < existing_purchase_date
          releases_by_album[album_id]['purchase_date'] = this_purchase_date
        end
      end

      releases_by_album[album_id]['tracks'] << {
        'title' => track['name'],
        'position' => track['track_number'],
        'filepath' => track['external_urls']['spotify']
      }
    end

    # Fetch album details to get label information
    enrich_albums_with_labels(releases_by_album, access_token)

    releases_by_album.values
  end

  def enrich_albums_with_labels(releases_by_album, access_token)
    album_ids = releases_by_album.keys
    
    album_ids.each_slice(ALBUM_BATCH_SIZE) do |id_batch|
      ids_param = id_batch.join(',')
      response = HTTParty.get("#{BASE_URL}/albums", {
        query: { ids: ids_param },
        headers: { 'Authorization' => "Bearer #{access_token}" }
      })

      if response.success?
        data = JSON.parse(response.body)
        data['albums'].each do |album|
          if album && releases_by_album[album['id']]
            releases_by_album[album['id']]['label'] = album['label'] || nil
          end
        end
      else
        # Log error but don't fail the import
        puts "Warning: Failed to fetch album details for batch: #{response.body}"
      end
    end
  end

  def extract_year_from_date(date_string)
    return nil if date_string.blank?
    Date.parse(date_string).year
  rescue Date::Error
    nil
  end
end
