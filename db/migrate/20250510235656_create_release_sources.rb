class CreateReleaseSources < ActiveRecord::Migration[7.1]
  def change
    create_table :release_sources do |t|
      t.references :collection, null: false, foreign_key: true
      t.string :type

      t.timestamps
    end
  end
end
