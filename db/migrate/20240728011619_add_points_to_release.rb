class AddPointsToRelease < ActiveRecord::Migration[7.1]
  def change
    add_column :releases, :points, :integer, default: 0
  end
end
