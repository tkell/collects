desc "create folders from releases"

task :create_folders_from_releases => :environment do
  Collection.all.each do |collection|
    puts(collection)
    folders = {}
    collection.releases.each do |release|
      if release.folder.blank?
        next
      end

      if folders.include?(release.folder)
        folder = folders[release.folder]
        folder.releases << release
      else
        new_folder = Folder.new(collection_id: collection.id, name: release.folder, short_name: release.folder.slice(0, 2))
        new_folder.save!
        new_folder.releases << release
        folders[release.folder] = new_folder
        puts(folders)
      end
    end

    folders.each do |f|
      collection.folders << f
    end

  end
end
