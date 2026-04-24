require 'csv'
require 'digest'

class SpotifyExportifyCsvReleaseSource < ReleaseSource
  attr_accessor :raw_csv

  def import_releases(overwrite_strategy, current_releases, &block)
    all_releases = parse_csv_to_releases
    load_all_releases(all_releases, current_releases, overwrite_strategy, &block)
  end

  private

  def parse_csv_to_releases
    releases_by_key = {}
    track_counts = {}

    rows = CSV.parse(raw_csv, headers: true)
    rows.each do |row|
      track_uri = row['Track URI']
      track_id = track_uri.split(":").last
      album_name = row['Album Name']
      next if album_name.blank?

      first_artist = row['Artist Name(s)']&.split(';')&.first&.strip.to_s
      album_key = "#{album_name}|#{first_artist}"

      unless releases_by_key[album_key]
        track_counts[album_key] = 0
        releases_by_key[album_key] = {
          'external_id' => Digest::MD5.hexdigest(album_key), ## need to get the real spotify album id here, hmm
          'title' => album_name,
          'artist' => first_artist,
          'label' => row['Record Label'],
          'release_year' => extract_year(row['Release Date']),
          'purchase_date' => row['Added At'],
          'image_path' => "https://storage.googleapis.com/pr-newsroom-wp/1/2023/05/Spotify_Full_Logo_RGB_Green.png", ## images are _very_ temporary, yikes!
          'image_path_small' => "https://storage.googleapis.com/pr-newsroom-wp/1/2023/05/Spotify_Full_Logo_RGB_Green.png",
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

      track_counts[album_key] += 1
      releases_by_key[album_key]['tracks'] << {
        'title' => row['Track Name'],
        'position' => track_counts[album_key],
        'filepath' => "https://open.spotify.com/track/#{track_id}"
      }
    end

    releases_by_key.values
  end

  def extract_year(date_string)
    return nil if date_string.blank?
    date_string[0, 4].to_i
  end
end
