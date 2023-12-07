class AddItemToSubitem < ActiveRecord::Migration[7.1]
  def change
    add_reference :subitems, :item, null: false, foreign_key: true
  end
end
