desc "Delete music objects from the db"


task :delete_release, [:external_id, :collection_name] => :environment do |task, args|
  collection = Collection.find_by_name(args[:collection_name])
  release = Release.find_by_external_id_and_collection_id(args[:external_id], collection.id)

  puts("About to delete release: #{release}")
  puts("release has #{release.tracks.count} tracks, and #{release.variants.count} variants")
  puts("Are you sure? (y/n)")
  input = STDIN.gets.strip
  if input == 'y'
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




