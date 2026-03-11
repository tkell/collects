class ReleaseSource < ApplicationRecord
  belongs_to :collection

  def import_releases(overwrite_strategy, current_releases)
    raise NotImplementedError("This should be defined in each subclass!")
  end

  def convert_well_formatted(raw_releases)
    all_releases = []
    raw_release.each do | release_data |
      release_data["release_year"] = release_data["year"]
      release_data["external_id"] = release_data["id"].to_s
      release_data["image_path"] = release_data["image_url"]
      release_data.delete("id")
      release_data.delete("year")
      all_releases << release_data
    end

    all_releases
  end

  def load_all_releases(all_releases, current_releases, overwrite_strategy)
    level_increase = 0
    all_releases.each do | release_data |
      external_id = release_data["external_id"]
      existing_release = current_releases[external_id]
      if overwrite_strategy == "only_new" && existing_release.nil?
        Release.make_from(release_data, collection.id)
        level_increase += 1
      elsif overwrite_strategy == "update_existing" and existing_release
        Release.update_from(release_data, existing_release)
      end
    end
    new_level = collection.level + level_increase
    collection.update(level: new_level)
  end
end
