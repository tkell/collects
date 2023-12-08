class AddFolderToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :folder, :string
  end
end
