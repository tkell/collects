class SpotifyLikedSongsReleaseSource < ReleaseSource
  require_relative '../../lib/clients/spotify_client'

  def import_releases(overwrite_strategy, current_releases)
    spotify_account = get_spotify_linked_account
    raise "No Spotify account linked for this collection's user" unless spotify_account

    if spotify_account.expired?
      refresh_spotify_token(spotify_account)
    end

    client = SpotifyClient.new(spotify_account.access_token)

    puts "Starting import from Spotify"
    liked_tracks = client.fetch_liked_songs

    puts "Starting processing from Spotify"
    releases = process_spotify_tracks(liked_tracks)
    releases_with_labels = add_labels(releases, client)
    all_releases = releases_with_labels.values
    puts "Done processing, saving .."

    load_all_releases(all_releases, current_releases, overwrite_strategy)
  end

  private

  def get_spotify_linked_account
    collection.user.linked_accounts.find_by(provider: LinkedAccount::SPOTIFY)
  end

  def refresh_spotify_token(spotify_account)
    client = SpotifyClient.new(nil)
    token_data = client.refresh_token(spotify_account.refresh_token)
    spotify_account.update!(
      access_token: token_data['access_token'],
      expires_at: Time.current + token_data['expires_in'].to_i.seconds
    )
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

  def add_labels(releases_by_album, client)
    album_ids = releases_by_album.keys
    albums = client.fetch_albums(album_ids)
    albums.each do |album|
      if album && releases_by_album[album['id']]
        releases_by_album[album['id']]['label'] = album['label'] || nil
      end
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
