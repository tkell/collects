desc "Import music objects into the db"
task :import_music, [:source_file] => [:environment] do |task, args|


  {"id"=>2526210858, "title"=>"Whisper / Funkin", "artist"=>"100Hz", "label"=>"Oblong", "tracks"=>[{"position"=>"01", "title"=>"Whisper", "filepath"=>"/Volumes/Music/Albums/100Hz - Whisper : Funkin [Oblong]/01 - Whisper.flac"}, {"position"=>"02", "title"=>"Funkin", "filepath"=>"/Volumes/Music/Albums/100Hz - Whisper : Funkin [Oblong]/02 - Funkin.flac"}], "image_path"=>"/Volumes/Music/Albums/100Hz - Whisper : Funkin [Oblong]/cover.jpg"}
  require "json"
  filepath = "/Volumes/Bragi/Code/music-collection/organize-music/digital.json"
  file = File.open(filepath)
  data = JSON.load(file)
  file.close()

  collection = Collection.first

  data.each do | item_data |
    item = Item.new(title: item_data["title"], artist: item_data["artist"], label: item_data["label"])
    puts(item.title, item.artist)
    collection.items << item
    item.save
    break
  end
end
