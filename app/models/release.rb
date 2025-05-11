class Release < ApplicationRecord
  before_destroy :clean_up_variants

  belongs_to :collection
  has_many :garden_releases, dependent: :destroy
  has_many :tracks, dependent: :destroy
  has_many :variants, dependent: :destroy
  has_many :playbacks, dependent: :destroy


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
        external_id: release_data["external_id"],
        collection_id: collection_id
      )
      release.save

      tracks = release_data["tracks"]
      tracks.each do |track|
        track_id = release.external_id + "-" + track["position"].to_s
        t = Track.new(
          title: track["title"],
          position: track["position"].to_s,
          media_link: track["filepath"],
          external_id: track_id,
          purchase_date: release.purchase_date
        )
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

    def update_needed(release_data, release)
      fields_to_compare = ["title", "artist", "label", "release_year", "purchase_date"]
      fields_to_compare << "folder" if release.folder

      update_needed = false
      fields_to_compare.each do |field|
        if release_data[field].to_s != release.send(field).to_s
          print(release_data[field], release.send(field))
          update_needed = true
          break
        end
      end

      return update_needed
    end

    def tracks_updated_needed(release_data, release)
      # Trying to find if a single track has been changed is hard, so we look for an exact comparision
      tracks_data = release_data["tracks"]
      release_tracks = release.tracks
      if release_tracks.size != tracks_data.size
        return true
      end

      update_needed = false
      release.tracks.each_with_index do |track, index|
        new_data = tracks_data[index]
        if new_data["title"] != track.title || new_data["position"].to_s != track.position || new_data["filepath"] != track.media_link
          update_needed = true
          break
        end
      end

      return update_needed
    end

    def update_from(release_data, release)
      if update_needed(release_data, release)
        release.update(
          title: release_data["title"],
          artist: release_data["artist"],
          label: release_data["label"],
          release_year: release_data["release_year"],
          purchase_date: release_data["purchase_date"],
          folder:  release_data["folder"] || ""
        )
        release.save
      end

      if tracks_update_needed(release_data, release)
        # If we get a single thing different, we just re-load all the tracks.
        # This is cool because we don't use tracks as a reference for anything, yet.
        # but we will soon, so this will need to be _formalized_
        release.tracks.destroy_all
        tracks_data.each do |track|
          t = Track.new(title: track["title"], position: track["position"].to_s, media_link: track["filepath"])
          release.tracks << t
          t.save
        end
      end
    end
  end

  def as_json(options={})
    super(:include => [:tracks, :variants])
  end

  def current_variant
    variants.find(current_variant_id)
  end

  def clean_up_variants
    update(current_variant_id: nil)
    save
    puts("hmm")
    puts(current_variant_id)
    puts("hmm")
  end
end
