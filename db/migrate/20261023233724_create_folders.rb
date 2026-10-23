class CreateFolders < ActiveRecord::Migration[7.1]
  def change
    create_table :folders do |t|
      t.string :name
      t.string :short_name
      t.references :collection, null: false, foreign_key: true

      t.timestamps
    end
  end
end
