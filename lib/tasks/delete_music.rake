desc "Delete music objects from the db"


task :delete_release, [:external_id, :collection_name] => :environment do |task, args|
  collection = Collection.find_by_name(args[:collection_name])
  release = Release.where(external_id: args[:external_id], collection_id: collection.id).first

  if release.nil?
    puts("Release not found - check your external ID and collection name")
    exit
  end

  puts("About to delete release: #{release.artist} - #{release.title} [#{release.label}]")
  puts("release has #{release.tracks.count} tracks, and #{release.variants.count} variants")
  tracks_to_delete = release.tracks
  variants_to_delete = release.variants
  release.current_variant_id = nil
  release.save

  tracks_to_delete.each do |track|
    track.destroy
  end
  variants_to_delete.each do |variant|
    variant.destroy
  end
  release.destroy
end
