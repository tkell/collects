class AddExternalIdIndexToItems < ActiveRecord::Migration[7.1]
  def change
    add_index :items, :external_id, :unique => true
  end
end
