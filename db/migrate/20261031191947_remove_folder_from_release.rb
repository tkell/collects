class RemoveFolderFromRelease < ActiveRecord::Migration[7.1]
  def change
    remove_column :releases, :folder, :string
  end
end
