class AddFolderToReleases < ActiveRecord::Migration[7.1]
  def change
    add_reference :releases, :folder, null: true, foreign_key: true
  end
end
