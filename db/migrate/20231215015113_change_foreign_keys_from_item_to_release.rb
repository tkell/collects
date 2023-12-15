class ChangeForeignKeysFromItemToRelease < ActiveRecord::Migration[7.1]
  def change
    rename_column :tracks, :item_id, :release_id
    rename_column :garden_items, :item_id, :release_id
  end
end
