class RubyHashReleaseSource < ReleaseSource
  attr_accessor :raw_releases

  def import_releases(overwrite_strategy, current_releases)
    all_releases = []
    raw_releases.each do |release_data|
      release_data = release_data.dup
      release_data["release_year"] = release_data["year"]
      release_data["external_id"] = release_data["id"].to_s
      release_data["image_path"] = release_data["image_url"]
      release_data.delete("id")
      release_data.delete("year")
      all_releases << release_data
    end

    load_all_releases(all_releases, current_releases, overwrite_strategy)
  end
end
