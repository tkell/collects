class RemoveUniqueExternalIdIndexFromCollections < ActiveRecord::Migration[7.1]
  def change
    remove_index :collections, name: 'idx_16450_index_releases_on_external_id'
  end
end
