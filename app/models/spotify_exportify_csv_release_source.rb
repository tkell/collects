require 'csv'
require 'rspotify'

class SpotifyExportifyCsvReleaseSource < ReleaseSource
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
        'external_id' => track_id,
        'title' => row['Track Name'],
        'position' => nil,
        'filepath' => "https://open.spotify.com/track/#{track_id}"
      }
    end

    releases_by_key.values
  end

  def enrich_with_spotify_data(releases)
    releases.each do |release|
      # Let's get the album images
      first_track_id = release['tracks'].first&.dig('external_id')
      next unless first_track_id

      track = find_one(RSpotify::Track, first_track_id)
      next unless track

      album_uri = track.album.uri
      release['external_id'] = album_uri
      album_id = album_uri.split(':').last

      album = find_one(RSpotify::Album, album_id)
      next unless album

      images = album.images || []
      release['image_path'] = images.first&.dig('url')
      small = images.find { |i| i['width'] == 300 && i['height'] == 300 }
      release['image_path_small'] = small&.dig('url')

      # We can't trust the album lookup - we often get album id / track id mismatches for region reasons,
      # so we'll just be dumb and do one per track.
      release['tracks'].each do |t|
        track = find_one(RSpotify::Track, t['external_id'])
        disc_number = track.disc_number
        position = "#{track.track_number}"
        if disc_number > 1
          position = "#{disc_number} - #{track.track_number}"
        end
        t['position'] = position
        t['filepath'] = "https://open.spotify.com/track/#{t['external_id']}?context=#{release['external_id']}"
      end
    end
  end

  def find_one(klass, id)
    klass.find(id)
  rescue => e
    puts "Warning: Failed to fetch #{klass.name} #{id}: #{e.message}"
    nil
  end

  def extract_year(date_string)
    return nil if date_string.blank?
    date_string[0, 4].to_i
  end
end
