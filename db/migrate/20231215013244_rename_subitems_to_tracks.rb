class RenameSubitemsToTracks < ActiveRecord::Migration[7.1]
  def change
    rename_table :subitems, :tracks
  end
end
