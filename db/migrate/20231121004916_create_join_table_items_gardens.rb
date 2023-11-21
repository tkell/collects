class CreateJoinTableItemsGardens < ActiveRecord::Migration[7.1]
  def change
    create_join_table :items, :gardens do |t|
      t.index [:item_id, :garden_id]
      t.index [:garden_id, :item_id]
    end
  end
end
