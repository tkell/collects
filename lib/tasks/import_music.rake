desc "Import music objects into the db"

task :import_digital_prod do
  filepath = "digital.json"
  Rake::Task[:import_music].invoke(filepath, "Digital", "only_new")
end

task :import_vinyl_prod do
  filepath = "vinyl.json"
  Rake::Task[:import_music].invoke(filepath, "Vinyl", "only_new")
end

task :import_digital_local do
  filepath = "/Volumes/Bragi/Code/music-collection/tessellates/app/digital/release_source.json"
  Rake::Task[:import_music].invoke(filepath, "Digital", "only_new")
end

task :import_vinyl_local do
  filepath = "/Volumes/Bragi/Code/music-collection/tessellates/app/vinyl/release_source.json"
  Rake::Task[:import_music].invoke(filepath, "Vinyl", "only_new")
end

task :import_music, [:source_file, :collection_name, :overwrite_style] => [:environment] do |task, args|
  require "json"

  puts("Importing music to #{args[:collection_name]}, with #{args[:overwrite_style]}")
  filepath = args[:source_file]
  file = File.open(filepath)
  data = JSON.load(file)
  file.close()

  collection = Collection.where(name: args[:collection_name]).first
  if args[:overwrite_style] == "destroy_all"
    puts("Destroying all releases in #{collection.name} ...")
    all_releases = Release.where(collection_id: collection.id)
    all_releases.each do | release |
      release.tracks.destroy_all
      release.destroy
    end
  end

  data.each do | release_data |
    external_id = release_data["id"].to_s
    maybe_release = Release.where(external_id: external_id)

    if args[:overwrite_style] == "update_existing" && maybe_release.size > 0
      update_release(collection, release_data, maybe_release.first)
    elsif maybe_release.size == 0
      make_release(collection, release_data)
    else
      puts("Got some sort of bad state, check your arguments!")
    end
  end
end

def update_release(collection, release_data, release)
  if not release_data.except("tracks", "image_path", "id") < release.attributes
    puts("Updating #{release.title} with new data")
    release.update(
      title: release_data["title"],
      artist: release_data["artist"],
      label: release_data["label"],
      folder:  release_data["folder"] || "",
      colors: release_data["colors"]
    )
    release.save
  end

  # Trying to find if a single track has been changed is hard, so we look for an exact comparision
  # If we get a single think different, we just re-load all the tracks.
  # This is cool because we don't use tracks as a reference for anything ... yet!
  tracks_dirty = false
  tracks_data = release_data["tracks"]
  release.tracks.each_with_index do |track, index|
    if not tracks_data[index].except("filepath") < track.attributes or tracks_data[index]["filepath"] != track.attributes["media_link"]
      tracks_dirty = true
      break
    end
  end

  if tracks_dirty
    puts("Updating #{release.title} with new tracks")
    release.tracks.destroy_all
    tracks_data.each do |track|
      t = Track.new(title: track["title"], position: track["position"].to_s, media_link: track["filepath"])
      release.tracks << t
      t.save
    end
  end
end

def make_release(collection, release_data)
  print(".")
  release = Release.new(
    title: release_data["title"],
    artist: release_data["artist"],
    label: release_data["label"],
    folder:  release_data["folder"] || "",
    colors: release_data["colors"],
    external_id: release_data["id"].to_s
  )
  collection.releases << release
  release.save

  tracks = release_data["tracks"]
  tracks.each do |track|
    t = Track.new(title: track["title"], position: track["position"].to_s, media_link: track["filepath"])
    release.tracks << t
    t.save
  end
end
