class AddNumberToSubitems < ActiveRecord::Migration[7.1]
  def change
    add_column :subitems, :number, :integer
  end
end
