class AddColorsToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :colors, :string
  end
end
