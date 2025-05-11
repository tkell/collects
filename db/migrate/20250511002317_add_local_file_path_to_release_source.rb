class AddLocalFilePathToReleaseSource < ActiveRecord::Migration[7.1]
  def change
    add_column :release_sources, :local_file_path, :string
  end
end
