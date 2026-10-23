desc "create folders from releases"

task :create_folders_from_releases => :environment do
  collections.each do |collection|
    folders = {}
    collection.releases.each do |release|
      if folders.include?(release.folder)
        continue
      end

      new_folder = Folder.new(name: release.folder, short_name: release.folder.slice(0, 2))
      folders[release.folder] = new_folder
    end

    folders.each do |f|
      f.save!
      collection.folders << f
    end
    collection.save!

  end
end
