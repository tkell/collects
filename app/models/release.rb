class Release < ApplicationRecord
  belongs_to :collection
  has_many :garden_releases
  has_many :tracks
  has_many :variants

  # class methods
  class << self 
    def make_from(release_data, collection_id)
      release = Release.new(
        title: release_data["title"],
        artist: release_data["artist"],
        label: release_data["label"],
        folder:  release_data["folder"] || "",
        release_year: release_data["release_year"],
        purchase_date: release_data["purchase_date"] || Date.new(1982, 9, 23),
        external_id: release_data["id"].to_s,
        collection_id: collection_id
      )
      release.save

      tracks = release_data["tracks"]
      tracks.each do |track|
        t = Track.new(title: track["title"], position: track["position"].to_s, media_link: track["filepath"])
        release.tracks << t
        t.save
      end

      image_path = release_data["image_path"]
      variant = Variant.new(
        release_id: release.id,
        image_path: image_path,
        colors: release_data["colors"],
        name: "Standard",
        is_standard: true
      )
      release.variants << variant
      variant.save
      release.current_variant_id = variant.id
      release.save
    end
  end

  def as_json(options={})
    super(:include => [:tracks, :variants])
  end

  def current_variant
    variants.find(current_variant_id)
  end
end
