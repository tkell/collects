desc "calculate starting collection levels"


task :calculate_collection_levels => :environment do
  collections = Collection.all
  collections.each do |collection|
    if collection.level.nil?
      collection.level = Release.where(collection_id: collection.id).count
      puts "Collection #{collection.id} is assigned a collection level of: #{collection.level}"
      collection.save
    else
      puts "Collection #{collection.id} has an extant collection level, skipping"
    end

  end
end
