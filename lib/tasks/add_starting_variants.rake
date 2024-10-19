desc "add starting variants"

task :add_starting_variants => :environment do
  collections = Collection.all
  collections.each do |collection|
    collection.releases.each do |release|
      next unless release.variants.count == 0

      image_path = "https://tide-pool.ca/tessellates/#{collection.name.downcase}/images/#{release.external_id}"
      v = Variant.new(release_id: release.id, image_path: image_path)
      release.variants << v
      release.current_variant_id = v.id

      release.save!
      v.save!
    end
  end
end


task :copy_colors_to_variants => :environment do
  collections = Collection.all
  collections.each do |collection|
    collection.releases.each do |release|
      v = release.current_variant
      v.colors = release.colors
      v.save!
      end
    end
  end

