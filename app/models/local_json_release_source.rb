class LocalJsonReleaseSource < ReleaseSource
  def import_releases(overwrite_strategy, current_releases)
    require "json"
    file = File.open(local_file_path)
    data = JSON.load(file)
    file.close()

    all_releases = []
    data.each do | release_data |
      release_data["release_year"] = release_data["year"]
      release_data["external_id"] = release_data["id"].to_s
      release_data["image_path"] = get_image_path(release_data)
      release_data.delete("id")
      release_data.delete("year")
      all_releases << release_data
    end

    load_all_releases(all_releases, current_releases, overwrite_strategy) # via superclass
  end

  private

  # eventually need to move this constant somewhere else, hmm
  def get_image_path(release_data)
    external_id = release_data["id"].to_s
    "https://tide-pool.ca/tessellates/#{collection.name.downcase}/images/#{external_id}.jpg"
  end
    
end
