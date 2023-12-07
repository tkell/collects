class AddExternalIdToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :external_id, :string
  end
end
