class ReleaseSource < ApplicationRecord
  belongs_to :collection

  def load_all_releases(releases)
    releases.each do | release_data |
      Release.make_from(release_data, collection.id)
    end
  end
end
