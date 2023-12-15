class RenameItemstoReleases < ActiveRecord::Migration[7.1]
  def change
    rename_table :items, :releases
  end
end
