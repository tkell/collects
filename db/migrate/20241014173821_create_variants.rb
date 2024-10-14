class CreateVariants < ActiveRecord::Migration[7.1]
  def change
    create_table :variants do |t|
      t.string :image_path
      t.references :release, null: false, foreign_key: true

      t.timestamps
    end
  end
end
