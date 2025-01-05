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
  if args[:overwrite_style] == "destroy_all" && collection
    puts("Destroying all releases in #{collection.name} ...")
    all_releases = Release.where(collection_id: collection.id)
    all_releases.each do | release |
      release.tracks.destroy_all
      release.destroy
    end
  end

  data.each do | release_data |
    external_id = release_data["id"].to_s
    release_data["release_year"] = release_data["year"]
    release_data.delete("year")

    if args[:overwrite_style] == "destroy_all"
      make_release(collection, release_data)
      next
    end

    maybe_release = Release.where(external_id: external_id)
    if args[:overwrite_style] == "update_existing" && maybe_release.size > 0
      update_release(collection, release_data, maybe_release.first)
    elsif args[:overwrite_style] == "only_new" && maybe_release.size == 0
      make_release(collection, release_data)
    else
      print("-")
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
      release_year: release_data["release_year"],
      purchase_date: release_data["purchase_date"] || Date.new(1982, 9, 23),
      folder:  release_data["folder"] || "",
    )
    release.save
  else
    print("-")
  end

  # Trying to find if a single track has been changed is hard, so we look for an exact comparision
  # If we get a single thing different, we just re-load all the tracks.
  # This is cool because we don't use tracks as a reference for anything ... yet!
  tracks_dirty = false
  tracks_data = release_data["tracks"]
  release.tracks.each_with_index do |track, index|
    if not tracks_data[index].except("filepath") < track.attributes or tracks_data[index]["filepath"] != track.attributes["media_link"]
      tracks_dirty = true
      break
    end
  end

  if tracks_dirty || release.tracks.size != tracks_data.size
    puts("Updating #{release.title} with new tracks")
    release.tracks.destroy_all
    tracks_data.each do |track|
      t = Track.new(title: track["title"], position: track["position"].to_s, media_link: track["filepath"])
      release.tracks << t
      t.save
    end
  else
    print("not updating tracks for #{release.title}")
  end
end

def make_release(collection, release_data)
  print(".")
  release = Release.new(
    title: release_data["title"],
    artist: release_data["artist"],
    label: release_data["label"],
    folder:  release_data["folder"] || "",
    release_year: release_data["release_year"],
    purchase_date: release_data["purchase_date"] || Date.new(1982, 9, 23),
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

  image_path = "https://tide-pool.ca/tessellates/#{collection.name.downcase}/images/#{release.external_id}.jpg"
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
