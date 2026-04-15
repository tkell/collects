require "open-uri"
require "tempfile"

class ReleaseSource < ApplicationRecord
  belongs_to :collection

  def import_releases(overwrite_strategy, current_releases, &block)
    raise NotImplementedError("This should be defined in each subclass!")
  end

  def convert_well_formatted(raw_releases)
    all_releases = []
    raw_releases.each do |release_data|
      release_data["release_year"] = release_data["year"]
      release_data["external_id"] = release_data["id"].to_s
      release_data["image_path"] = release_data["image_url"]
      release_data.delete("id")
      release_data.delete("year")

      all_releases << release_data
    end

    all_releases
  end

  def load_all_releases(all_releases, current_releases, overwrite_strategy, &block)
    level_increase = 0
    all_releases.each do | release_data |
      external_id = release_data["external_id"]
      existing_release = current_releases[external_id]

      if overwrite_strategy == "only_new"
        if existing_release.nil?
          # only add colors to new releases!
          if release_data["colors"].blank?
            release_data["colors"] = extract_image_colors(release_data["image_path"])
          end

          Release.make_from(release_data, collection.id)
          yield release_data if block_given?
          level_increase += 1
        else
          res = { colors: existing_release.current_variant.colors }
          yield res if block_given?
        end
      end

      if overwrite_strategy == "update_existing" and existing_release
        Release.update_from(release_data, existing_release)
      end
    end
    new_level = collection.level + level_increase
    collection.update!(level: new_level)
  end

  private

  def extract_image_colors(image_url)
    colors = []
    return colors if image_url.blank?

    Tempfile.create(["release_image", ".jpg"], binmode: true) do |temp_file|
      URI.open(image_url) { |f| temp_file.write(f.read) }
      colors = Miro::DominantColors.new(temp_file.path).to_hex.first(2).map(&:upcase)
    end

    colors
  end
end
