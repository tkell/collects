class RemoveNumberFromSubitems < ActiveRecord::Migration[7.1]
  def change
    remove_column :subitems, :number, :integer
  end
end
