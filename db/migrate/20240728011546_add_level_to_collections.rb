class AddLevelToCollections < ActiveRecord::Migration[7.1]
  def change
    add_column :collections, :level, :integer
  end
end
