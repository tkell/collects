class RubyHashReleaseSource < ReleaseSource
  attr_accessor :raw_releases

  def import_releases(overwrite_strategy, current_releases)
    all_releases = convert_well_formatted(raw_releases)
    load_all_releases(all_releases, current_releases, overwrite_strategy)
  end
end
