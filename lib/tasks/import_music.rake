desc "Import music objects into the db"

task :import_digital do
  Rake::Task[:import_music].invoke("Digital", "only_new")
end

task :import_vinyl do
  Rake::Task[:import_music].invoke("Vinyl", "only_new")
end

task :import_music, [:collection_name, :overwrite_style] => [:environment] do |task, args|
  collection = Collection.where(name: args[:collection_name]).first
  if !collection
    abort("Collection not found")
  end

  collection.update(args[:overwrite_style])
end

task :delete_collection, [:collection_name] => [:environment] do |task, args|
  collection = Collection.where(name: args[:collection_name]).first
  if !collection
    abort("Collection not found")
  end

  collection.destroy
end
