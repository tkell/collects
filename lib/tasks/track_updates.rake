desc "Update Tracks after migrations"

task :add_purchase_date_to_tracks => [:environment] do |task, args|
  Release.all.each do |r|
    purchase_date = r.purchase_date
    r.tracks.each do |t|
      t.purchase_date = purchase_date
      t.save
    end
  end
end

task :add_external_id_to_tracks => [:environment] do |task, args|
  Release.all.each do |r|
    release_id = r.external_id
    r.tracks.each do |t|
      external_id = release_id + "-" + t.position
      t.external_id = external_id
      t.save
    end
  end
end
