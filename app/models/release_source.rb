class ReleaseSource < ApplicationRecord
  belong_to :collection

  def load_all_releases(releases)
    releases.each do | release_data |
      Release.make_from(release_data, collection)
    end
  end
end
