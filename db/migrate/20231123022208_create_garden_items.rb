class CreateGardenItems < ActiveRecord::Migration[7.1]
  def change
    create_table :garden_items do |t|
      t.references :item, null: false, foreign_key: true
      t.references :garden, null: false, foreign_key: true

      t.timestamps
    end
  end
end
