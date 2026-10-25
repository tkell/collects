desc "create folders from releases"

task :create_folders_from_releases => :environment do
  collections.each do |collection|
    folders = {}
    collection.releases.each do |release|
      if folders.include?(release.folder)
        folder = folders[release.folder]
        folder << release
        release.save!
      else
        new_folder = Folder.new(name: release.folder, short_name: release.folder.slice(0, 2))
        new_folder.save!
        new_folder << release
        release.save!
        folders[release.folder] = new_folder
      end
    end

    folders.each do |f|
      collection.folders << f
    end
    collection.save!

  end
end
