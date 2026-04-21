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


task :add_name_and_is_standard_to_variants => :environment do
  Variant.all.each do |v|
    v.name = "Standard"
    v.is_standard = true
    v.save!
  end
end

task :add_jpg_to_image_path => :environment do
  Variant.all.each do |v|
    v.image_path = v.image_path + ".jpg"
    v.save!
  end
end

task :backfill_image_path_small => :environment do
  variants = Variant.where("image_path LIKE ?", "%tide-pool.ca%")
  puts "Backfilling #{variants.count} variants..."
  variants.each do |v|
    image_path_small = v.image_path.split(".jpg")[0] + "-small.jpg"
    v.update!(image_path_small: image_path_small)
  end
  puts "Done."
end
