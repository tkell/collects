class CreateSubitems < ActiveRecord::Migration[7.1]
  def change
    create_table :subitems do |t|
      t.string :title
      t.string :media_link

      t.timestamps
    end
  end
end
