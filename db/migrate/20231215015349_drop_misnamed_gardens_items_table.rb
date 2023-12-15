class DropMisnamedGardensItemsTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :gardens_items 
  end
end
