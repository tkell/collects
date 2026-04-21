require "open-uri"
require "tempfile"
require "net/http"
require "google/cloud/storage"

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
      release_data["image_path_small"] = release_data["image_url_small"]
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
          # only image-process new release if we have to:
          if release_data["colors"].blank? || release_data["image_path_small"].blank?
            _, variant = Release.make_from(release_data, collection.id)
            colors, small_image_url = process_image(release_data["image_path"], release_data, variant)
            variant.colors = colors
            variant.image_path_small = small_image_url
            variant.save!
          else
            _, _ = Release.make_from(release_data, collection.id)
          end

          yield release_data if block_given?
          level_increase += 1
        else
          colors = existing_release[1]
          res = { colors: colors }
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

  def process_image(image_url, release_data, variant)
    begin
      Tempfile.create(["release_image", ".jpg"], binmode: true) do |temp_file|
        URI.open(image_url) { |f| temp_file.write(f.read) }

        # get colors
        if release_data[:colors].blank?
          colors = Miro::DominantColors.new(temp_file.path).to_hex.first(2).map(&:upcase)
        else
          colors = release_data[:colors]
        end

        # make small image
        if release_data[:image_path_small].blank?
          small_image_name = "#{release_data[:external_id]}-v#{variant.id}-small.jpg"
          small_image_path = "https://storage.googleapis.com/collects-images/"
          small_image = ImageProcessing::MiniMagick
            .source(temp_file.path)
            .resize_to_limit(350, 350)
            .call
          bucket = Google::Cloud::Storage.new(
            project_id: "collects-416256",
            credentials: "/home/rails/collects/keys/collects-416256-gcs-uploader-pk.json"
          ).bucket("collects-images")

          bucket.create_file(small_image.path, small_image_name)
          small_image_url = "#{small_image_path}#{small_image_name}"
        else
          small_image_url = release_data[:image_path_small]
        end

        return colors, small_image_url
      end
    rescue StandardError => e
      puts(e.message)
      colors = ["#000000", "#FFFFFF"]
      small_image_path = ""
      return colors, small_image_path
    end
  end
end
