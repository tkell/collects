require "google/cloud/storage"

class Variant < ApplicationRecord
  belongs_to :release

  serialize :colors, coder: JSON, type: Array

  before_destroy :delete_gcs_images

  private

  def delete_gcs_images
    storage = Google::Cloud::Storage.new(
      project_id: "collects-416256",
      credentials: ENV['GCS_BUCKET_KEY_PATH']
    )
    bucket = storage.bucket("collects-images")
    external_id = release.external_id
    ["#{external_id}-v#{id}.jpg", "#{external_id}-v#{id}-small.jpg"].each do |name|
      bucket.file(name)&.delete
    end
  rescue => e
    Rails.logger.error("Failed to delete GCS images for variant #{id}: #{e.message}")
  end
end
