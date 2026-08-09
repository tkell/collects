class DiscogsOAuthReleaseSource < ReleaseSource
  def import_releases(overwrite_strategy, current_releases, &block)
    all_releases = convert_well_formatted(raw_releases)

    # the collection endpoint doesn't give us tracklists, and each one is its
    # own rate-limited request, so we only pay for releases we're about to make
    all_releases.each do |release|
      next if current_releases.key?(release["external_id"])
      yield({ type: 'querying', message: "Fetching tracks for #{release['artist']} - #{release['title']} ..." }) if block_given?
      add_tracklist(release)
    end

    load_all_releases(all_releases, current_releases, overwrite_strategy, &block)
  end

  def input_count
    raw_releases.length
  end

  # convert discogs collection items to well-formatted releases.
  # we use the big cover image for both sizes - load_all_releases will still
  # pull colors off it, but skips the resize + upload.
  def convert_well_formatted(raw_releases)
    raw_releases.map do |item|
      info = item["basic_information"] || {}
      cover_image = info["cover_image"]

      {
        "external_id" => info["id"].to_s,
        "title" => info["title"],
        "artist" => artist_name(info["artists"]),
        "label" => info["labels"]&.first&.dig("name"),
        "release_year" => info["year"],
        "purchase_date" => item["date_added"],
        "image_path" => cover_image,
        "image_path_small" => cover_image,
        "tracks" => []
      }
    end
  end

  private

  def raw_releases
    @raw_releases ||= client.collection_releases(client.username)
  end

  def client
    @client ||= DiscogsOAuthClient.new(
      collection.user.linked_accounts.find_by(provider: "discogs")
    )
  end

  # discogs disambiguates same-named artists as "Fingers Inc. (2)" - we don't
  # want the number, and compilations come back as several artists
  def artist_name(artists)
    return "" if artists.blank?

    artists
      .map { |a| a["name"].to_s.sub(/\s*\(\d+\)\z/, "").strip }
      .reject(&:blank?)
      .uniq
      .join(", ")
  end

  def add_tracklist(release)
    data = client.release(release["external_id"])

    # headings and index tracks have no position, and Release.make_from sorts
    # on position, so they'd blow up the sort as well as being noise
    release["tracks"] = (data["tracklist"] || []).filter_map do |track|
      position = track["position"].to_s.strip
      next if position.blank?

      {
        "external_id" => "#{release['external_id']}-#{position}",
        "title" => track["title"],
        "position" => position,
        "filepath" => nil
      }
    end
  rescue DiscogsOAuthClient::Error => e
    puts "Warning: failed to fetch tracklist for #{release['external_id']}: #{e.message}"
  end
end
