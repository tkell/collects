class LocalJsonReleaseSource < ReleaseSource
  def import_releases(overwrite_strategy, current_releases)
    require "json"
    file = File.open(local_file_path)
    data = JSON.load(file)
    file.close()

    all_releases = convert_well_formatted(data)
    load_all_releases(all_releases, current_releases, overwrite_strategy) # via superclass
  end
end
