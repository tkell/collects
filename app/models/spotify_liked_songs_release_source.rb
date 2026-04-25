require 'rspotify'

class SpotifyLikedSongsReleaseSource < ReleaseSource
  ALBUM_BATCH_SIZE = 20
  SAVED_TRACKS_PAGE_SIZE = 50

  def import_releases(overwrite_strategy, current_releases)
    spotify_account = get_spotify_linked_account
    raise "No Spotify account linked for this collection's user" unless spotify_account

    spotify_account.refresh_spotify_token! if spotify_account.expired?

    user = build_rspotify_user(spotify_account)

    puts "Starting import from Spotify"
    liked_tracks = fetch_all_saved_tracks(user)

    puts "Starting processing from Spotify"
    releases = process_spotify_tracks(liked_tracks)
    releases_with_labels = add_labels(releases)
    all_releases = releases_with_labels.values
    puts "Done processing, saving .."

    load_all_releases(all_releases, current_releases, overwrite_strategy)
  end

  private

  def get_spotify_linked_account
    collection.user.linked_accounts.find_by(provider: LinkedAccount::SPOTIFY)
  end

  def build_rspotify_user(spotify_account)
    RSpotify::User.new(
      'credentials' => {
        'token' => spotify_account.access_token,
        'refresh_token' => spotify_account.refresh_token,
        'expires_at' => spotify_account.expires_at&.to_i,
        'expires' => true
      },
      'id' => 'me'
    )
  end

  def fetch_all_saved_tracks(user)
    items = []
    offset = 0
    loop do
      RSpotify.raw_response = true
      raw = user.saved_tracks(limit: SAVED_TRACKS_PAGE_SIZE, offset: offset)
      RSpotify.raw_response = false

      page = raw.is_a?(String) ? JSON.parse(raw) : raw
      batch = page['items'] || []
      break if batch.empty?

      items.concat(batch)
      break if batch.size < SAVED_TRACKS_PAGE_SIZE
      offset += SAVED_TRACKS_PAGE_SIZE
    end
    items
  end

  def process_spotify_tracks(spotify_tracks)
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

    releases_by_album
  end

  def add_labels(releases_by_album)
    album_ids = releases_by_album.keys
    album_ids.each_slice(ALBUM_BATCH_SIZE) do |batch|
      albums = Array(RSpotify::Album.find(batch)).compact
      albums.each do |album|
        if album && releases_by_album[album.id]
          releases_by_album[album.id]['label'] = album.label || nil
        end
      end
    rescue => e
      puts "Warning: Failed to fetch album details for batch: #{e.message}"
    end

    releases_by_album
  end

  def extract_year_from_date(date_string)
    return nil if date_string.blank?
    Date.parse(date_string).year
  rescue Date::Error
    nil
  end
end
