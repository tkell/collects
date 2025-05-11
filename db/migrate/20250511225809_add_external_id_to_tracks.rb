class AddExternalIdToTracks < ActiveRecord::Migration[7.1]
  def change
    add_column :tracks, :external_id, :string
  end
end
