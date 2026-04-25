require 'csv'
require 'rspotify'

class SpotifyExportifyCsvReleaseSource < ReleaseSource
  TRACK_BATCH_SIZE = 50
  ALBUM_BATCH_SIZE = 20

  attr_accessor :raw_csv

  def import_releases(overwrite_strategy, current_releases, &block)
    all_releases = parse_csv_to_releases
    config = OAuthConfig.get_provider_config('spotify')
    RSpotify.authenticate(config[:client_id], config[:client_secret])
    enrich_with_spotify_data(all_releases)
    load_all_releases(all_releases, current_releases, overwrite_strategy, &block)
  end

  private

  def parse_csv_to_releases
    releases_by_key = {}

    rows = CSV.parse(raw_csv, headers: true)
    rows.each do |row|
      track_uri = row['Track URI']
      track_id = track_uri.split(":").last
      album_name = row['Album Name']
      next if album_name.blank?

      first_artist = row['Artist Name(s)']&.split(';')&.first&.strip.to_s
      album_key = "#{album_name}|#{first_artist}"

      unless releases_by_key[album_key]
        releases_by_key[album_key] = {
          'external_id' => nil,
          'title' => album_name,
          'artist' => first_artist,
          'label' => row['Record Label'],
          'release_year' => extract_year(row['Release Date']),
          'purchase_date' => row['Added At'],
          'image_path' => nil,
          'image_path_small' => nil,
          'tracks' => []
        }
      end

      # Take the earliest added_at as the purchase date
      added_at = row['Added At']
      if added_at.present? && added_at < releases_by_key[album_key]['purchase_date'].to_s
        releases_by_key[album_key]['purchase_date'] = added_at
      end

      # Accumulate unique artists across tracks (for compilations)
      track_artists = row['Artist Name(s)']&.split(';')&.map(&:strip) || []
      existing_artists = releases_by_key[album_key]['artist'].split(', ')
      new_artists = track_artists - existing_artists
      unless new_artists.empty?
        releases_by_key[album_key]['artist'] = (existing_artists + new_artists).join(', ')
      end

      releases_by_key[album_key]['tracks'] << {
        'spotify_track_id' => track_id,
        'title' => row['Track Name'],
        'position' => nil,
        'filepath' => "https://open.spotify.com/track/#{track_id}"
      }
    end

    releases_by_key.values
  end

  def enrich_with_spotify_data(releases)
    first_track_ids = releases.map { |r| r['tracks'].first&.dig('spotify_track_id') }.compact
    tracks = batch_find(RSpotify::Track, first_track_ids, TRACK_BATCH_SIZE)
    album_uri_by_track_id = tracks.each_with_object({}) do |track, memo|
      memo[track.id] = track.album.uri
    end

    album_ids = []
    releases.each do |release|
      first_track_id = release['tracks'].first&.dig('spotify_track_id')
      album_uri = album_uri_by_track_id[first_track_id]
      next unless album_uri

      release['external_id'] = album_uri
      album_ids << album_uri.split(':').last
    end

    albums = batch_find(RSpotify::Album, album_ids, ALBUM_BATCH_SIZE)
    albums_by_id = albums.index_by(&:id)

    releases.each do |release|
      next unless release['external_id']
      album_id = release['external_id'].split(':').last
      album = albums_by_id[album_id]
      next unless album

      images = album.images || []
      release['image_path'] = images.first&.dig('url')
      small = images.find { |i| i['width'] == 300 && i['height'] == 300 }
      release['image_path_small'] = small&.dig('url')

      position_by_track_id = (album.tracks || []).each_with_object({}) do |item, memo|
        memo[item.id] = item.track_number
      end
      release['tracks'].each do |track|
        track['position'] = position_by_track_id[track['spotify_track_id']]
        track['filepath'] = "https://open.spotify.com/track/#{track['spotify_track_id']}?context=#{release['external_id']}"
      end
    end

    releases.each do |release|
      release['tracks'].each { |t| t.delete('spotify_track_id') }
    end
  end

  def batch_find(klass, ids, batch_size)
    results = []
    ids.each_slice(batch_size) do |batch|
      found = Array(klass.find(batch)).compact
      results.concat(found)
    rescue => e
      puts "Warning: Failed to fetch #{klass.name} batch: #{e.message}"
    end
    results
  end

  def extract_year(date_string)
    return nil if date_string.blank?
    date_string[0, 4].to_i
  end
end
