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
  data.each do | item_data |
    external_id = item_data["id"].to_s
    maybe_items = Item.where(external_id: external_id)
    if maybe_items.size == 0
      print(".")
      item = Item.new(
        title: item_data["title"],
        artist: item_data["artist"],
        label: item_data["label"],
        folder:  item_data["folder"] || "",
        colors: item_data["colors"],
        external_id: item_data["id"].to_s
      )
      collection.items << item
      item.save

      tracks = item_data["tracks"]
      tracks.each do |track|
        t = Subitem.new(title: track["title"], position: track["position"].to_s, media_link: "-")
        item.tracks << t
        t.save
      end
    end
  end
end
