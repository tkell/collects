desc "Import music objects into the db"

task :import_digital do
  filepath = "/Volumes/Bragi/Code/music-collection/tessellates/app/digital/release_source.json"
  Rake::Task[:import_music].invoke(filepath, "Digital")
end

task :import_vinyl do
  filepath = "/Volumes/Bragi/Code/music-collection/tessellates/app/vinyl/release_source.json"
  Rake::Task[:import_music].invoke(filepath, "Vinyl")
end

task :import_music, [:source_file, :collection_name] => [:environment] do |task, args|

  require "json"
  filepath = args[:source_file]
  file = File.open(filepath)
  data = JSON.load(file)
  file.close()

  collection = Collection.where(name: args[:collection_name]).first
  data.each do | release_data |
    external_id = release_data["id"].to_s
    maybe_release = Release.where(external_id: external_id)
    if maybe_release.size == 0
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
  end
end
