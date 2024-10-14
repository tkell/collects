desc "add starting variants"

task :add_starting_variants => :environment do
  collections = Collection.all
  collections.each do |collection|
    collection.releases.each do |release|
      next unless release.variants.count == 0

      image_path = "https://tide-pool.ca/tessellates/#{collection.name.downcase}/images/#{release.external_id}"
      v = Variant.new(release_id: release.id, image_path: image_path)
      release.variants << v

      release.save!
      v.save!
    end
  end
end


