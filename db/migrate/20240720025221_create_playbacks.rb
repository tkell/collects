class CreatePlaybacks < ActiveRecord::Migration[7.1]
  def change
    create_table :playbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :release, null: false, foreign_key: true

      t.timestamps
    end
  end
end
