class RenameGardenItemstoGardenReleases < ActiveRecord::Migration[7.1]
  def change
    rename_table :garden_items, :garden_releases
  end
end
