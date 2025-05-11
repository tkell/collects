class ReleaseSource < ApplicationRecord
  belongs_to :collection

  def import_releases(overwrite_strategy, current_releases)
    raise NotImplementedError("This should be defined in each subclass!")
  end

  def load_all_releases(all_releases, current_releases, overwrite_strategy)
    all_releases.each do | release_data |
      external_id = release_data["external_id"]
      existing_release = current_releases[external_id]
      if overwrite_strategy == "only_new" && existing_release.nil?
        Release.make_from(release_data, collection.id)
      elsif overwrite_strategy == "update_existing" and existing_release
        Release.update_from(release_data, existing_release)
      end
    end
  end
end
