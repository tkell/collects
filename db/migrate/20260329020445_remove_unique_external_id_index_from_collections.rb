class RemoveUniqueExternalIdIndexFromCollections < ActiveRecord::Migration[7.1]
  def change
    ## different names on production and local, yikes?
    # remove_index :collections, name: 'idx_16454_index_releases_on_external_id' # prod
    # remove_index :collections, name: 'idx_16450_index_releases_on_external_id' # local
  end
end
